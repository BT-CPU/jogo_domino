from datetime import datetime, timedelta
from typing import Optional
import os

import mysql.connector
from mysql.connector import pooling
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
import random

# ---------------------------------------------------------------------------
# Estado em memória das partidas ativas
# ---------------------------------------------------------------------------
PARTIDAS_ATIVAS: dict = {}

# Limite para evitar vazamento de memória (Bug F corrigido)
_MAX_PARTIDAS_ATIVAS = 500
_EXPIRACAO_HORAS = 2


def _limpar_partidas_expiradas() -> None:
    """Remove partidas sem atividade há mais de _EXPIRACAO_HORAS horas."""
    agora = datetime.now()
    limite = timedelta(hours=_EXPIRACAO_HORAS)
    expiradas = [
        pid for pid, p in PARTIDAS_ATIVAS.items()
        if agora - p.get("ultima_atividade", agora) > limite
    ]
    for pid in expiradas:
        del PARTIDAS_ATIVAS[pid]


try:
    import bcrypt
except ImportError:
    bcrypt = None

app = FastAPI(title="Domino da Quimica API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Bug E (segurança) corrigido: credenciais via variáveis de ambiente.
# Configure no Railway: DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME.
# ---------------------------------------------------------------------------
DB_CONFIG = {
    "host":     os.getenv("DB_HOST", "mysql-17b3ac90-guitursi-f0c2.j.aivencloud.com"),
    "port":     int(os.getenv("DB_PORT", "20062")),
    "user":     os.getenv("DB_USER", "avnadmin"),
    "password": os.getenv("DB_PASSWORD", ""),   # NUNCA deixe a senha aqui em produção
    "database": os.getenv("DB_NAME", "defaultdb"),
    "ssl_disabled": False,
}

DB_POOL = pooling.MySQLConnectionPool(
    pool_name="domino_pool",
    pool_size=8,
    pool_reset_session=True,
    **DB_CONFIG,
)


def get_connection():
    return DB_POOL.get_connection()


# ---------------------------------------------------------------------------
# Modelos Pydantic
# ---------------------------------------------------------------------------

class CadastroUsuario(BaseModel):
    nome: str
    email: EmailStr
    senha: str
    aceite_lgpd: bool
    perfil: str = "aluno"


class LoginUsuario(BaseModel):
    email: EmailStr
    senha: str


class PartidaFinalizadaPayload(BaseModel):
    id_usuario: int
    nivel_dificuldade: int
    tempo_segundos: int = 0
    # Bug C corrigido: qtd_acertos agora vem do servidor via id_partida;
    # estes campos são usados apenas como fallback se a partida não estiver mais
    # em memória (ex.: reinício do servidor).
    qtd_acertos: int = 0
    qtd_erros: int = 0
    id_partida: Optional[str] = None


class CriarPartidaPayload(BaseModel):
    id_usuario: int
    nivel_dificuldade: int


class JogarPecaPayload(BaseModel):
    id_partida: str
    id_peca: int
    ponta: str   # "esquerda" | "direita"


class ComprarPecaPayload(BaseModel):
    id_partida: str


# Reutilizado para /partidas/passar — mesma estrutura
PassarVezPayload = ComprarPecaPayload


class PecaDomino(BaseModel):
    id_peca: int
    visivel_esquerdo: str
    visivel_direito: str
    validador_esquerdo: int
    validador_direito: int


class StatusPartidaResponse(BaseModel):
    id_partida: str
    mesa: list[PecaDomino]
    mao_jogador: list[PecaDomino]
    status: str
    fim_de_jogo: bool
    quantidade_monte: int = 0
    # Bug C corrigido: acertos contados server-side
    qtd_acertos: int = 0
    # Bug B corrigido: sinaliza ao Flutter se o jogador tem jogadas válidas
    jogador_tem_jogadas: bool = True


# ---------------------------------------------------------------------------
# Funções auxiliares — banco de dados
# ---------------------------------------------------------------------------

def _iso_datetime(value):
    if value is None:
        return None
    if isinstance(value, str):
        return value
    return value.isoformat()


def _formatar_data_cadastro(value):
    if value is None:
        return None
    return value.strftime("%d/%m/%Y %H:%M")


def _buscar_usuario(cursor, id_usuario):
    cursor.execute(
        """
        SELECT id_usuario, nome, email, perfil
        FROM tb_usuario
        WHERE id_usuario = %s
        """,
        (id_usuario,),
    )
    return cursor.fetchone()


def _buscar_turma_aluno(cursor, id_usuario):
    cursor.execute(
        """
        SELECT MIN(t.nome_turma) AS turma
        FROM tb_aluno_turma at
        JOIN tb_turma t ON t.id_turma = at.id_turma
        WHERE at.id_usuario = %s
        """,
        (id_usuario,),
    )
    row = cursor.fetchone()
    return row["turma"] if row and row["turma"] else "Sem turma"


def _taxa_acerto(soma_acertos, soma_erros):
    total_acoes = (soma_acertos or 0) + (soma_erros or 0)
    return (
        float(round(((soma_acertos or 0) / total_acoes) * 100, 1))
        if total_acoes > 0
        else 0.0
    )


def _buscar_resumo_aluno(cursor, id_usuario):
    cursor.execute(
        """
        SELECT
            COUNT(*) AS total_partidas,
            COALESCE(SUM(qtd_acertos), 0) AS soma_acertos,
            COALESCE(SUM(qtd_erros), 0) AS soma_erros,
            MIN(NULLIF(tempo_segundos, 0)) AS melhor_tempo_segundos,
            MAX(data_partida) AS ultima_jogada
        FROM tb_partida
        WHERE id_usuario = %s
        """,
        (id_usuario,),
    )
    resumo = cursor.fetchone()
    return {
        "total_partidas": resumo["total_partidas"] or 0,
        "taxa_acerto_media": _taxa_acerto(
            resumo["soma_acertos"],
            resumo["soma_erros"],
        ),
        "melhor_tempo_segundos": resumo["melhor_tempo_segundos"],
        "ultima_jogada": _iso_datetime(resumo["ultima_jogada"]),
    }


def _buscar_historico_aluno(cursor, id_usuario, limite=20):
    cursor.execute(
        """
        SELECT
            id_partida,
            nivel_dificuldade,
            tempo_segundos,
            qtd_acertos,
            qtd_erros,
            data_partida
        FROM tb_partida
        WHERE id_usuario = %s
        ORDER BY data_partida DESC, id_partida DESC
        LIMIT %s
        """,
        (id_usuario, limite),
    )
    historico = cursor.fetchall()
    for partida in historico:
        partida["data_partida"] = _iso_datetime(partida["data_partida"])
    return historico


def _montar_relatorio_aluno(cursor, id_usuario):
    cursor.execute(
        """
        SELECT
            u.id_usuario,
            u.nome,
            COALESCE(MIN(t.nome_turma), 'Sem turma') AS turma,
            COUNT(p.id_partida) AS total_partidas,
            COALESCE(SUM(p.qtd_acertos), 0) AS soma_acertos,
            COALESCE(SUM(p.qtd_erros), 0) AS soma_erros,
            MIN(NULLIF(p.tempo_segundos, 0)) AS melhor_tempo_segundos,
            MAX(p.data_partida) AS ultima_jogada
        FROM tb_usuario u
        LEFT JOIN tb_aluno_turma at ON at.id_usuario = u.id_usuario
        LEFT JOIN tb_turma t ON t.id_turma = at.id_turma
        LEFT JOIN tb_partida p ON p.id_usuario = u.id_usuario
        WHERE u.id_usuario = %s
          AND u.perfil = 'aluno'
        GROUP BY u.id_usuario, u.nome
        """,
        (id_usuario,),
    )
    resumo_aluno = cursor.fetchone()
    if not resumo_aluno:
        raise HTTPException(status_code=404, detail="Aluno nao encontrado.")

    historico = _buscar_historico_aluno(cursor, id_usuario)

    return {
        "id_usuario": resumo_aluno["id_usuario"],
        "nome": resumo_aluno["nome"],
        "turma": resumo_aluno["turma"],
        "total_partidas": resumo_aluno["total_partidas"] or 0,
        "taxa_acerto_media": _taxa_acerto(
            resumo_aluno["soma_acertos"],
            resumo_aluno["soma_erros"],
        ),
        "melhor_tempo_segundos": resumo_aluno["melhor_tempo_segundos"],
        "ultima_jogada": _iso_datetime(resumo_aluno["ultima_jogada"]),
        "historico": historico,
    }


def _listar_resumos_alunos_professor(cursor, id_professor):
    cursor.execute(
        """
        SELECT COUNT(*) AS total
        FROM tb_turma
        WHERE id_professor = %s
        """,
        (id_professor,),
    )
    professor_tem_turma = (cursor.fetchone()["total"] or 0) > 0

    if professor_tem_turma:
        cursor.execute(
            """
            SELECT
                u.id_usuario,
                u.nome,
                COALESCE(MIN(t.nome_turma), 'Sem turma') AS turma,
                COUNT(p.id_partida) AS total_partidas,
                COALESCE(SUM(p.qtd_acertos), 0) AS soma_acertos,
                COALESCE(SUM(p.qtd_erros), 0) AS soma_erros,
                MIN(NULLIF(p.tempo_segundos, 0)) AS melhor_tempo_segundos,
                MAX(p.data_partida) AS ultima_jogada
            FROM tb_usuario u
            LEFT JOIN tb_aluno_turma at ON at.id_usuario = u.id_usuario
            LEFT JOIN tb_turma t ON t.id_turma = at.id_turma
            LEFT JOIN tb_partida p ON p.id_usuario = u.id_usuario
            WHERE u.perfil = 'aluno'
              AND t.id_professor = %s
            GROUP BY u.id_usuario, u.nome
            ORDER BY u.nome ASC
            """,
            (id_professor,),
        )
    else:
        cursor.execute(
            """
            SELECT
                u.id_usuario,
                u.nome,
                COALESCE(MIN(t.nome_turma), 'Sem turma') AS turma,
                COUNT(p.id_partida) AS total_partidas,
                COALESCE(SUM(p.qtd_acertos), 0) AS soma_acertos,
                COALESCE(SUM(p.qtd_erros), 0) AS soma_erros,
                MIN(NULLIF(p.tempo_segundos, 0)) AS melhor_tempo_segundos,
                MAX(p.data_partida) AS ultima_jogada
            FROM tb_usuario u
            LEFT JOIN tb_aluno_turma at ON at.id_usuario = u.id_usuario
            LEFT JOIN tb_turma t ON t.id_turma = at.id_turma
            LEFT JOIN tb_partida p ON p.id_usuario = u.id_usuario
            WHERE u.perfil = 'aluno'
            GROUP BY u.id_usuario, u.nome
            ORDER BY u.nome ASC
            """
        )

    return cursor.fetchall()


# ---------------------------------------------------------------------------
# Lógica do dominó — geração e validação
# ---------------------------------------------------------------------------

def _gerar_corrente_domino(nivel: int) -> list:
    """
    Bug A corrigido: geração balanceada de pares de classes.

    Antes: os pares dependiam de uma rotação de sequência aleatória,
    causando distribuição desigual (pares iguais, ex: ácido-ácido,
    apareciam muito menos que pares cruzados).

    Agora: todos os 16 pares possíveis (4 classes × 4 classes) aparecem
    exatamente 2 vezes nas 32 primeiras peças, mais 8 aleatórias para
    completar as 40 peças, garantindo variedade e equilíbrio.
    """
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT id_composto, formula, nome, id_classificacao FROM tb_composto")
    compostos = cursor.fetchall()

    compostos_por_classe: dict[int, list] = {1: [], 2: [], 3: [], 4: []}
    for c in compostos:
        compostos_por_classe[c["id_classificacao"]].append(c)

    classificacoes_nomes = {1: "Ácido", 2: "Base", 3: "Sal", 4: "Óxido"}

    propriedades_por_classe: dict[int, list] = {1: [], 2: [], 3: [], 4: []}
    if nivel == 3:
        cursor.execute("SELECT id_classificacao, propriedade FROM tb_propriedade_funcao")
        for p in cursor.fetchall():
            propriedades_por_classe[p["id_classificacao"]].append(p["propriedade"])

    cursor.close()
    conn.close()

    classes = [1, 2, 3, 4]

    # Gera todos os 16 pares possíveis (4×4), repete 2× = 32 peças balanceadas
    pares_base = [(cl_esq, cl_dir) for cl_esq in classes for cl_dir in classes]
    pares: list[tuple[int, int]] = pares_base * 2

    # Completa com 8 pares aleatórios para totalizar 40 peças
    pares += [random.choice(pares_base) for _ in range(8)]

    # Embaralha para que a distribuição não seja previsível
    random.shuffle(pares)

    pecas_geradas = []

    for id_peca, (cl_esq, cl_dir) in enumerate(pares, start=1):
        comp_esq = random.choice(compostos_por_classe[cl_esq])
        conteudo_esq = comp_esq["formula"]

        if nivel == 1:
            conteudo_dir = classificacoes_nomes[cl_dir]
        elif nivel == 2:
            comp_dir = random.choice(compostos_por_classe[cl_dir])
            conteudo_dir = comp_dir["nome"]
        else:
            conteudo_dir = random.choice(propriedades_por_classe[cl_dir])

        pecas_geradas.append({
            "id_peca": id_peca,
            "visivel_esquerdo": conteudo_esq,
            "visivel_direito": conteudo_dir,
            "validador_esquerdo": cl_esq,
            "validador_direito": cl_dir,
        })

    return pecas_geradas


def _obter_peca_jogavel_bot(
    mao_bot: list, mesa: list
) -> tuple[Optional[dict], str]:
    """Retorna a primeira peça jogável do bot e em qual ponta, ou (None, '')."""
    ponta_esq = mesa[0]
    ponta_dir = mesa[-1]

    for p in mao_bot:
        if p["validador_direito"] == ponta_esq["validador_esquerdo"]:
            return p, "esquerda"
        if p["validador_esquerdo"] == ponta_dir["validador_direito"]:
            return p, "direita"
    return None, ""


def _verificar_jogadas_possiveis(mao: list, mesa: list) -> bool:
    """Retorna True se existe ao menos uma peça jogável na mão informada."""
    ponta_esq = mesa[0]
    ponta_dir = mesa[-1]

    for p in mao:
        if (
            p["validador_direito"] == ponta_esq["validador_esquerdo"]
            or p["validador_esquerdo"] == ponta_dir["validador_direito"]
        ):
            return True
    return False


def _executar_turno_bot(partida: dict) -> str:
    """
    Bug D corrigido: o bot agora compra no máximo 1 peça por turno
    (antes esgotava o monte inteiro em uma única rodada).

    Executa o turno completo do bot e retorna a mensagem de status.
    Modifica `partida` in-place (mesa, mao_bot, monte_compras).
    """
    mesa = partida["mesa"]
    peca_bot, ponta_bot = _obter_peca_jogavel_bot(partida["mao_bot"], mesa)
    comprou = False

    # Compra no máximo 1 peça por turno antes de tentar jogar
    if not peca_bot and len(partida["monte_compras"]) > 0:
        carta = partida["monte_compras"].pop(0)
        partida["mao_bot"].append(carta)
        comprou = True
        peca_bot, ponta_bot = _obter_peca_jogavel_bot(partida["mao_bot"], mesa)

    if peca_bot:
        partida["mao_bot"].remove(peca_bot)
        if ponta_bot == "esquerda":
            mesa.insert(0, peca_bot)
        else:
            mesa.append(peca_bot)
        aviso = " comprou 1 peça e" if comprou else ""
        return f"O Bot{aviso} jogou na extremidade {ponta_bot}. Sua vez!"

    if comprou:
        return "O Bot comprou do monte, mas não encontrou combinação e passou a vez."
    return "O Bot não encontrou combinação e passou a vez."


def _checar_trancamento(id_partida: str, partida: dict) -> Optional[dict]:
    """
    Bug E corrigido: verifica trancamento após o turno do bot.

    Retorna o dict de resposta final se a partida trancou,
    ou None se o jogo pode continuar.
    """
    if len(partida["monte_compras"]) != 0:
        return None

    bot_pode = _verificar_jogadas_possiveis(partida["mao_bot"], partida["mesa"])
    jogador_pode = _verificar_jogadas_possiveis(partida["mao_jogador"], partida["mesa"])

    if bot_pode or jogador_pode:
        return None

    # Jogo trancado
    partida["fim_de_jogo"] = True
    qtd_j = len(partida["mao_jogador"])
    qtd_b = len(partida["mao_bot"])

    if qtd_j < qtd_b:
        msg = f"Jogo sem saídas! Você venceu por ter menos peças ({qtd_j} x {qtd_b})."
    elif qtd_b < qtd_j:
        msg = f"Jogo sem saídas! Bot venceu por ter menos peças ({qtd_b} x {qtd_j})."
    else:
        msg = "Jogo trancado! Empate técnico."

    return _build_response(id_partida, partida, msg, fim_de_jogo=True)


def _build_response(
    id_partida: str,
    partida: dict,
    status: str,
    fim_de_jogo: bool = False,
) -> dict:
    """Monta o dict de resposta padrão, incluindo campos novos do Bug B/C/E."""
    jogador_tem_jogadas = (
        False
        if fim_de_jogo
        else _verificar_jogadas_possiveis(partida["mao_jogador"], partida["mesa"])
    )
    return {
        "id_partida": id_partida,
        "mesa": partida["mesa"],
        "mao_jogador": partida["mao_jogador"],
        "status": status,
        "fim_de_jogo": fim_de_jogo,
        "quantidade_monte": len(partida["monte_compras"]),
        "qtd_acertos": partida["qtd_acertos"],
        "jogador_tem_jogadas": jogador_tem_jogadas,
    }


# ---------------------------------------------------------------------------
# Rotas — usuários
# ---------------------------------------------------------------------------

@app.get("/")
def root():
    return {"status": "API Domino da Quimica online"}


@app.post("/usuarios", status_code=201)
def cadastrar_usuario(dados: CadastroUsuario):
    if bcrypt is None:
        raise HTTPException(status_code=503, detail="Cadastro indisponivel neste ambiente local.")

    if not dados.aceite_lgpd:
        raise HTTPException(status_code=400, detail="Aceite da LGPD e obrigatorio.")

    if dados.perfil not in ("aluno", "professor"):
        raise HTTPException(status_code=400, detail="Perfil invalido. Use 'aluno' ou 'professor'.")

    senha_hash = bcrypt.hashpw(dados.senha.encode(), bcrypt.gensalt()).decode()

    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO tb_usuario (nome, email, senha_hash, perfil, aceite_lgpd)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (dados.nome, dados.email, senha_hash, dados.perfil, dados.aceite_lgpd),
        )
        conn.commit()
        novo_id = cursor.lastrowid
        cursor.close()
        conn.close()
        perfil_label = "Professor" if dados.perfil == "professor" else "Aluno"
        return {"id_usuario": novo_id, "mensagem": f"{perfil_label} cadastrado com sucesso."}
    except mysql.connector.IntegrityError:
        raise HTTPException(status_code=409, detail="E-mail ja cadastrado.")
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@app.get("/usuarios")
def listar_usuarios():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT id_usuario, nome, email, perfil, data_cadastro
            FROM tb_usuario
            ORDER BY perfil ASC, data_cadastro DESC
            """
        )
        usuarios = cursor.fetchall()
        cursor.close()
        conn.close()
        for usuario in usuarios:
            usuario["data_cadastro"] = _formatar_data_cadastro(usuario["data_cadastro"])
        return usuarios
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@app.delete("/usuarios/{id_usuario}", status_code=200)
def excluir_usuario(id_usuario: int):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM tb_usuario WHERE id_usuario = %s", (id_usuario,))
        conn.commit()
        affected = cursor.rowcount
        cursor.close()
        conn.close()

        if affected == 0:
            raise HTTPException(status_code=404, detail="Usuario nao encontrado.")
        return {"mensagem": "Usuario excluido com sucesso."}
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@app.post("/login")
def login(dados: LoginUsuario):
    if bcrypt is None:
        raise HTTPException(status_code=503, detail="Login indisponivel neste ambiente local.")

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT id_usuario, nome, email, senha_hash, perfil
            FROM tb_usuario
            WHERE email = %s
            """,
            (dados.email,),
        )
        usuario = cursor.fetchone()
        cursor.close()
        conn.close()

        if not usuario:
            raise HTTPException(status_code=401, detail="Usuario nao encontrado.")

        if not bcrypt.checkpw(dados.senha.encode(), usuario["senha_hash"].encode()):
            raise HTTPException(status_code=401, detail="Senha incorreta.")

        return {
            "id_usuario": usuario["id_usuario"],
            "nome": usuario["nome"],
            "email": usuario["email"],
            "perfil": usuario["perfil"],
            "mensagem": "Login realizado com sucesso",
        }
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


# ---------------------------------------------------------------------------
# Rotas — relatórios
# ---------------------------------------------------------------------------

@app.post("/partidas/finalizar", status_code=201)
def finalizar_partida(dados: PartidaFinalizadaPayload):
    if dados.nivel_dificuldade not in (1, 2, 3):
        raise HTTPException(status_code=400, detail="Nivel de dificuldade invalido.")

    # Bug C corrigido: usa qtd_acertos do servidor se a partida ainda estiver ativa.
    qtd_acertos = dados.qtd_acertos
    qtd_erros = dados.qtd_erros

    if dados.id_partida and dados.id_partida in PARTIDAS_ATIVAS:
        p = PARTIDAS_ATIVAS[dados.id_partida]
        qtd_acertos = p.get("qtd_acertos", dados.qtd_acertos)
        qtd_erros = dados.qtd_erros  # erros ainda vêm do cliente (Flutter)
        del PARTIDAS_ATIVAS[dados.id_partida]  # libera memória

    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        usuario = _buscar_usuario(cursor, dados.id_usuario)
        if not usuario:
            raise HTTPException(status_code=404, detail="Usuario nao encontrado.")

        cursor.close()
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO tb_partida (
                id_usuario,
                nivel_dificuldade,
                tempo_segundos,
                qtd_acertos,
                qtd_erros,
                data_partida
            )
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (
                dados.id_usuario,
                dados.nivel_dificuldade,
                dados.tempo_segundos,
                qtd_acertos,
                qtd_erros,
                datetime.now(),
            ),
        )
        conn.commit()
        id_partida_db = cursor.lastrowid
        cursor.close()
        conn.close()
        return {"id_partida": id_partida_db, "mensagem": "Partida registrada com sucesso."}
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@app.get("/relatorios/aluno/{id_usuario}")
def relatorio_aluno(id_usuario: int):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        relatorio = _montar_relatorio_aluno(cursor, id_usuario)
        cursor.close()
        conn.close()
        return relatorio
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@app.get("/relatorios/professor/{id_professor}")
def relatorio_professor(id_professor: int):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        professor = _buscar_usuario(cursor, id_professor)
        if not professor or professor["perfil"] != "professor":
            raise HTTPException(status_code=404, detail="Professor nao encontrado.")

        alunos_base = _listar_resumos_alunos_professor(cursor, id_professor)
        alunos = []
        total_partidas_turma = 0
        taxas = []

        for aluno in alunos_base:
            taxa = _taxa_acerto(aluno["soma_acertos"], aluno["soma_erros"])
            total_partidas = aluno["total_partidas"] or 0
            alunos.append(
                {
                    "id_usuario": aluno["id_usuario"],
                    "nome": aluno["nome"],
                    "turma": aluno["turma"],
                    "total_partidas": total_partidas,
                    "taxa_acerto_media": taxa,
                    "melhor_tempo_segundos": aluno["melhor_tempo_segundos"],
                    "ultima_jogada": _iso_datetime(aluno["ultima_jogada"]),
                }
            )
            total_partidas_turma += total_partidas
            if total_partidas > 0:
                taxas.append(taxa)

        media_acerto_turma = round(sum(taxas) / len(taxas), 1) if taxas else 0.0

        cursor.close()
        conn.close()

        return {
            "id_professor": professor["id_usuario"],
            "nome_professor": professor["nome"],
            "media_acerto_turma": media_acerto_turma,
            "total_partidas_turma": total_partidas_turma,
            "alunos": alunos,
        }
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


# ---------------------------------------------------------------------------
# Rotas — partidas (lógica do jogo)
# ---------------------------------------------------------------------------

@app.post("/partidas/criar", status_code=201, response_model=StatusPartidaResponse)
def criar_partida(payload: CriarPartidaPayload):
    if payload.nivel_dificuldade not in (1, 2, 3):
        raise HTTPException(status_code=400, detail="Nível de dificuldade inválido.")

    # Bug F corrigido: limpa partidas expiradas antes de criar uma nova,
    # evitando crescimento ilimitado do dicionário em memória.
    _limpar_partidas_expiradas()
    if len(PARTIDAS_ATIVAS) >= _MAX_PARTIDAS_ATIVAS:
        raise HTTPException(
            status_code=503,
            detail="Servidor com muitas partidas ativas. Tente novamente em instantes.",
        )

    todas_pecas = _gerar_corrente_domino(payload.nivel_dificuldade)
    random.shuffle(todas_pecas)

    mao_jogador   = todas_pecas[0:7]
    mao_bot       = todas_pecas[7:14]
    mesa          = [todas_pecas[14]]
    monte_compras = todas_pecas[15:40]

    id_partida = f"partida_{payload.id_usuario}_{int(datetime.now().timestamp())}"

    PARTIDAS_ATIVAS[id_partida] = {
        "id_usuario":        payload.id_usuario,
        "nivel":             payload.nivel_dificuldade,
        "mesa":              mesa,
        "mao_jogador":       mao_jogador,
        "mao_bot":           mao_bot,
        "monte_compras":     monte_compras,
        "fim_de_jogo":       False,
        "resultado":         None,
        "qtd_acertos":       0,          # Bug C: contador server-side
        "ultima_atividade":  datetime.now(),  # Bug F: para limpeza
    }

    return _build_response(
        id_partida,
        PARTIDAS_ATIVAS[id_partida],
        "Partida iniciada! Faça uma combinação ou compre peças do monte.",
    )


@app.post("/partidas/comprar", response_model=StatusPartidaResponse)
def comprar_peca(payload: ComprarPecaPayload):
    if payload.id_partida not in PARTIDAS_ATIVAS:
        raise HTTPException(status_code=404, detail="Partida não encontrada.")

    partida = PARTIDAS_ATIVAS[payload.id_partida]
    if partida["fim_de_jogo"]:
        raise HTTPException(status_code=400, detail="Esta partida já foi encerrada.")

    if len(partida["monte_compras"]) == 0:
        raise HTTPException(status_code=422, detail="O monte está vazio!")

    nova_peca = partida["monte_compras"].pop(0)
    partida["mao_jogador"].append(nova_peca)
    partida["ultima_atividade"] = datetime.now()

    return _build_response(
        payload.id_partida,
        partida,
        "Você comprou uma peça do monte.",
    )


@app.post("/partidas/passar", response_model=StatusPartidaResponse)
def passar_vez(payload: ComprarPecaPayload):
    """
    Bug B corrigido: permite ao jogador passar a vez quando não tem jogadas
    válidas e o monte está vazio.

    Validações:
    - Só permite passar se o jogador realmente não tiver jogadas possíveis.
    - Só permite passar se o monte estiver vazio (deve comprar primeiro).
    """
    if payload.id_partida not in PARTIDAS_ATIVAS:
        raise HTTPException(status_code=404, detail="Partida não encontrada.")

    partida = PARTIDAS_ATIVAS[payload.id_partida]
    if partida["fim_de_jogo"]:
        raise HTTPException(status_code=400, detail="Esta partida já foi encerrada.")

    mesa = partida["mesa"]

    if _verificar_jogadas_possiveis(partida["mao_jogador"], mesa):
        raise HTTPException(
            status_code=400,
            detail="Você ainda tem jogadas possíveis! Jogue uma peça antes de passar.",
        )

    if len(partida["monte_compras"]) > 0:
        raise HTTPException(
            status_code=400,
            detail="Ainda há peças no monte. Compre uma antes de passar.",
        )

    partida["ultima_atividade"] = datetime.now()

    # Executa o turno do bot
    status_bot = _executar_turno_bot(partida)

    # Verificação de vitória do bot
    if len(partida["mao_bot"]) == 0:
        partida["fim_de_jogo"] = True
        partida["resultado"] = "Vitória do Bot"
        return _build_response(
            payload.id_partida,
            partida,
            "O Bot fechou o jogo!",
            fim_de_jogo=True,
        )

    # Verificação de trancamento (Bug E corrigido)
    trancamento = _checar_trancamento(payload.id_partida, partida)
    if trancamento:
        return trancamento

    return _build_response(payload.id_partida, partida, f"Você passou. {status_bot}")


@app.post("/partidas/jogar", response_model=StatusPartidaResponse)
def jogar_peca(payload: JogarPecaPayload):
    if payload.id_partida not in PARTIDAS_ATIVAS:
        raise HTTPException(status_code=404, detail="Partida não encontrada ou expirada.")

    partida = PARTIDAS_ATIVAS[payload.id_partida]
    if partida["fim_de_jogo"]:
        raise HTTPException(status_code=400, detail="Esta partida já foi encerrada.")

    peca_jogador = next(
        (p for p in partida["mao_jogador"] if p["id_peca"] == payload.id_peca),
        None,
    )
    if not peca_jogador:
        raise HTTPException(status_code=400, detail="Você não possui essa peça na sua mão.")

    mesa = partida["mesa"]
    ponta_esq_mesa = mesa[0]
    ponta_dir_mesa = mesa[-1]
    jogada_valida = False
    nova_peca_mesa = peca_jogador.copy()

    if payload.ponta == "esquerda":
        if peca_jogador["validador_direito"] == ponta_esq_mesa["validador_esquerdo"]:
            mesa.insert(0, nova_peca_mesa)
            jogada_valida = True
    elif payload.ponta == "direita":
        if peca_jogador["validador_esquerdo"] == ponta_dir_mesa["validador_direito"]:
            mesa.append(nova_peca_mesa)
            jogada_valida = True

    if not jogada_valida:
        raise HTTPException(
            status_code=422,
            detail="Combinação química incorreta! Tente outra peça ou extremidade.",
        )

    # Bug C corrigido: acerto contabilizado no servidor
    partida["mao_jogador"].remove(peca_jogador)
    partida["qtd_acertos"] += 1
    partida["ultima_atividade"] = datetime.now()

    # Verificação de vitória do jogador
    if len(partida["mao_jogador"]) == 0:
        partida["fim_de_jogo"] = True
        partida["resultado"] = "Vitória do Jogador"
        return _build_response(
            payload.id_partida,
            partida,
            "Você venceu! Todas as peças foram descartadas.",
            fim_de_jogo=True,
        )

    # Bug D corrigido: bot compra no máximo 1 peça por turno
    status_bot = _executar_turno_bot(partida)

    # Verificação de vitória do bot
    if len(partida["mao_bot"]) == 0:
        partida["fim_de_jogo"] = True
        partida["resultado"] = "Vitória do Bot"
        return _build_response(
            payload.id_partida,
            partida,
            "O Bot fechou o jogo antes de você!",
            fim_de_jogo=True,
        )

    # Bug E corrigido: verificação de trancamento logo após o turno do bot
    trancamento = _checar_trancamento(payload.id_partida, partida)
    if trancamento:
        return trancamento

    return _build_response(payload.id_partida, partida, status_bot)