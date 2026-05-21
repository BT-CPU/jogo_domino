from datetime import datetime

import mysql.connector
from mysql.connector import pooling
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
import random

PARTIDAS_ATIVAS = {}

try:
    import bcrypt
except ImportError:  # pragma: no cover - local preview fallback
    bcrypt = None

app = FastAPI(title="Domino da Quimica API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_CONFIG = {
    "host": "mysql-17b3ac90-guitursi-f0c2.j.aivencloud.com",
    "port": 20062,
    "user": "avnadmin",
    "password": "AVNS__zDss8p43pIUQo8PyRf",
    "database": "defaultdb",
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
    qtd_acertos: int = 0
    qtd_erros: int = 0

class CriarPartidaPayload(BaseModel):
    id_usuario: int
    nivel_dificuldade: int

class JogarPecaPayload(BaseModel):
    id_partida: str
    id_peca: int
    ponta: str

class ComprarPecaPayload(BaseModel):
    id_partida: str

# [CORREÇÃO BUG 1] Payload para o novo endpoint /partidas/passar
class PassarVezPayload(BaseModel):
    id_partida: str

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


# ==============================================================================
# LÓGICA DO JOGO
# ==============================================================================

def _gerar_corrente_domino(nivel: int) -> list:
    """
    Gera as 40 peças do dominó como uma corrente hamiltoniana garantindo que
    toda peça[i].validador_direito == peça[i+1].validador_esquerdo.

    [CORREÇÃO BUG 3] No nível 2, o lado direito de cada peça agora exibe o
    NOME do composto cuja FÓRMULA aparecerá no lado esquerdo da próxima peça.
    Antes, o composto do lado esquerdo e o nome do lado direito eram sorteados
    independentemente, quebrando a correspondência fórmula ↔ nome.
    """
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT id_composto, formula, nome, id_classificacao FROM tb_composto")
    compostos = cursor.fetchall()

    compostos_por_classe = {1: [], 2: [], 3: [], 4: []}
    for c in compostos:
        compostos_por_classe[c["id_classificacao"]].append(c)

    classificacoes_nomes = {1: "Ácido", 2: "Base", 3: "Sal", 4: "Óxido"}

    propriedades_por_classe = {1: [], 2: [], 3: [], 4: []}
    if nivel == 3:
        cursor.execute("SELECT id_classificacao, propriedade FROM tb_propriedade_funcao")
        propriedades = cursor.fetchall()
        for p in propriedades:
            propriedades_por_classe[p["id_classificacao"]].append(p["propriedade"])

    cursor.close()
    conn.close()

    # Gera a sequência de 40 classes (10 repetições de [1,2,3,4] embaralhadas)
    sequencia_classes = []
    classes = [1, 2, 3, 4]
    for _ in range(10):
        random.shuffle(classes)
        sequencia_classes.extend(classes)

    # [CORREÇÃO BUG 3] Sorteia antecipadamente UM composto para cada posição
    # da sequência. Isso garante que, no nível 2, o nome no lado direito da
    # peça[i] pertença ao mesmo composto cuja fórmula aparece no lado esquerdo
    # da peça[i+1] — ou seja, o aluno sempre associa fórmula ↔ nome corretos.
    compostos_sequencia = [
        random.choice(compostos_por_classe[cl]) for cl in sequencia_classes
    ]

    # sequencia_direita é a sequencia_esquerda rotacionada em 1 posição.
    # Isso garante: peça[i].validador_direito == peça[i+1].validador_esquerdo
    sequencia_esquerda = sequencia_classes.copy()
    sequencia_direita = sequencia_classes[1:] + [sequencia_classes[0]]

    pecas_geradas = []
    id_peca_tracker = 1

    for i, (cl_esq, cl_dir) in enumerate(zip(sequencia_esquerda, sequencia_direita)):
        comp_esq = compostos_sequencia[i]
        conteudo_esq = comp_esq["formula"]

        if nivel == 1:
            # Lado direito = nome da classe funcional do próximo composto
            conteudo_dir = classificacoes_nomes[cl_dir]

        elif nivel == 2:
            # [CORREÇÃO BUG 3] Lado direito = nome do composto da posição (i+1),
            # que é exatamente o composto cuja fórmula aparecerá à esquerda na
            # peça seguinte. O encaixe exige que o aluno reconheça a relação
            # fórmula ↔ nome do MESMO composto, não de compostos aleatórios.
            prox_i = (i + 1) % len(compostos_sequencia)
            conteudo_dir = compostos_sequencia[prox_i]["nome"]

        else:  # nivel == 3
            # Lado direito = propriedade aleatória da classe do próximo composto
            conteudo_dir = random.choice(propriedades_por_classe[cl_dir])

        pecas_geradas.append({
            "id_peca": id_peca_tracker,
            "visivel_esquerdo": conteudo_esq,
            "visivel_direito": conteudo_dir,
            "validador_esquerdo": cl_esq,
            "validador_direito": cl_dir,
        })
        id_peca_tracker += 1

    return pecas_geradas


def _obter_peca_jogavel_bot(mao_bot, mesa):
    """Retorna a primeira peça jogável do bot e a ponta alvo, ou (None, '')."""
    ponta_esquerda_mesa = mesa[0]
    ponta_direita_mesa = mesa[-1]

    for p_bot in mao_bot:
        if p_bot["validador_direito"] == ponta_esquerda_mesa["validador_esquerdo"]:
            return p_bot, "esquerda"
        elif p_bot["validador_esquerdo"] == ponta_direita_mesa["validador_direito"]:
            return p_bot, "direita"
    return None, ""


def _verificar_jogadas_possiveis(mao, mesa):
    """Retorna True se alguma peça da mão encaixa em qualquer ponta da mesa."""
    ponta_esquerda_mesa = mesa[0]
    ponta_direita_mesa = mesa[-1]

    for p in mao:
        if (p["validador_direito"] == ponta_esquerda_mesa["validador_esquerdo"] or
                p["validador_esquerdo"] == ponta_direita_mesa["validador_direito"]):
            return True
    return False


def _processar_turno_bot(id_partida: str, partida: dict) -> dict:
    """
    Executa o turno completo do bot após uma jogada ou passagem do jogador.

    [CORREÇÃO BUG 2] O bot agora compra APENAS UMA peça por turno antes de
    jogar, em vez de drenar o monte inteiro em uma única chamada. Se mesmo
    após a compra não houver jogada válida, o bot passa a vez — respeitando
    as regras clássicas do dominó.

    Também detecta e resolve o trancamento (monte vazio + nenhum dos dois pode
    jogar) e a vitória do bot.
    """
    mesa = partida["mesa"]

    peca_bot, ponta_bot = _obter_peca_jogavel_bot(partida["mao_bot"], mesa)

    # [CORREÇÃO BUG 2] Compra UMA peça do monte se não tiver jogada disponível.
    # Na versão anterior, o while consumia o monte inteiro de uma vez.
    pecas_compradas = 0
    if not peca_bot and len(partida["monte_compras"]) > 0:
        carta = partida["monte_compras"].pop(0)
        partida["mao_bot"].append(carta)
        pecas_compradas = 1
        peca_bot, ponta_bot = _obter_peca_jogavel_bot(partida["mao_bot"], mesa)

    if peca_bot:
        partida["mao_bot"].remove(peca_bot)
        if ponta_bot == "esquerda":
            mesa.insert(0, peca_bot)
        else:
            mesa.append(peca_bot)

        aviso_compra = (
            f" comprou {pecas_compradas} peça(s) do monte e"
            if pecas_compradas > 0
            else ""
        )
        status_bot = f"O Bot{aviso_compra} jogou na extremidade {ponta_bot}. Sua vez!"
    else:
        # Bot passou a vez (sem jogada válida e sem peças no monte)
        status_bot = "O Bot não encontrou combinação química e passou a vez!"

    # Verifica vitória do bot
    if len(partida["mao_bot"]) == 0:
        partida["fim_de_jogo"] = True
        partida["resultado"] = "Vitória do Bot"
        return {
            "id_partida": id_partida,
            "mesa": mesa,
            "mao_jogador": partida["mao_jogador"],
            "status": "O Bot fechou o jogo antes de você!",
            "fim_de_jogo": True,
            "quantidade_monte": len(partida["monte_compras"]),
        }

    # Verifica trancamento: monte vazio e nenhum dos dois pode jogar
    if len(partida["monte_compras"]) == 0:
        bot_pode = _verificar_jogadas_possiveis(partida["mao_bot"], mesa)
        jogador_pode = _verificar_jogadas_possiveis(partida["mao_jogador"], mesa)

        if not bot_pode and not jogador_pode:
            partida["fim_de_jogo"] = True
            qtd_jogador = len(partida["mao_jogador"])
            qtd_bot = len(partida["mao_bot"])

            if qtd_jogador < qtd_bot:
                msg_final = (
                    f"Jogo sem saídas! Você venceu por ter menos peças "
                    f"({qtd_jogador} contra {qtd_bot})."
                )
            elif qtd_bot < qtd_jogador:
                msg_final = (
                    f"Jogo sem saídas! O Bot venceu por ter menos peças "
                    f"({qtd_bot} contra {qtd_jogador})."
                )
            else:
                msg_final = "Jogo trancado! Empate técnico."

            return {
                "id_partida": id_partida,
                "mesa": mesa,
                "mao_jogador": partida["mao_jogador"],
                "status": msg_final,
                "fim_de_jogo": True,
                "quantidade_monte": 0,
            }

    return {
        "id_partida": id_partida,
        "mesa": mesa,
        "mao_jogador": partida["mao_jogador"],
        "status": status_bot,
        "fim_de_jogo": False,
        "quantidade_monte": len(partida["monte_compras"]),
    }


# ==============================================================================
# ROTAS
# ==============================================================================

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

        senha_correta = bcrypt.checkpw(dados.senha.encode(), usuario["senha_hash"].encode())
        if not senha_correta:
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


@app.post("/partidas/finalizar", status_code=201)
def finalizar_partida(dados: PartidaFinalizadaPayload):
    if dados.nivel_dificuldade not in (1, 2, 3):
        raise HTTPException(status_code=400, detail="Nivel de dificuldade invalido.")

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
                dados.qtd_acertos,
                dados.qtd_erros,
                datetime.now(),
            ),
        )
        conn.commit()
        id_partida = cursor.lastrowid
        cursor.close()
        conn.close()
        return {"id_partida": id_partida, "mensagem": "Partida registrada com sucesso."}
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


@app.post("/partidas/criar", status_code=201, response_model=StatusPartidaResponse)
def criar_partida(payload: CriarPartidaPayload):
    if payload.nivel_dificuldade not in (1, 2, 3):
        raise HTTPException(status_code=400, detail="Nível de dificuldade inválido.")

    # 1. Gera as 40 peças e embaralha completamente
    todas_pecas = _gerar_corrente_domino(payload.nivel_dificuldade)
    random.shuffle(todas_pecas)

    # 2. Divide conforme a regra de ouro do Dominó
    mao_jogador = todas_pecas[0:7]
    mao_bot = todas_pecas[7:14]
    mesa = [todas_pecas[14]]
    monte_compras = todas_pecas[15:40]

    # 3. Salva o estado em memória
    id_partida = f"partida_{payload.id_usuario}_{int(datetime.now().timestamp())}"
    PARTIDAS_ATIVAS[id_partida] = {
        "id_usuario": payload.id_usuario,
        "nivel": payload.nivel_dificuldade,
        "mesa": mesa,
        "mao_jogador": mao_jogador,
        "mao_bot": mao_bot,
        "monte_compras": monte_compras,
        "fim_de_jogo": False,
        "resultado": None,
    }

    return {
        "id_partida": id_partida,
        "mesa": mesa,
        "mao_jogador": mao_jogador,
        "status": "Partida iniciada! Faça uma combinação ou compre peças do monte.",
        "fim_de_jogo": False,
        "quantidade_monte": len(monte_compras),
    }


@app.post("/partidas/comprar", response_model=StatusPartidaResponse)
def comprar_peca(payload: ComprarPecaPayload):
    if payload.id_partida not in PARTIDAS_ATIVAS:
        raise HTTPException(status_code=404, detail="Partida não encontrada.")

    partida = PARTIDAS_ATIVAS[payload.id_partida]
    if partida["fim_de_jogo"]:
        raise HTTPException(status_code=400, detail="Esta partida já foi encerrada.")

    monte = partida["monte_compras"]
    if len(monte) == 0:
        raise HTTPException(status_code=422, detail="O monte está vazio!")

    nova_peca = monte.pop(0)
    partida["mao_jogador"].append(nova_peca)

    return {
        "id_partida": payload.id_partida,
        "mesa": partida["mesa"],
        "mao_jogador": partida["mao_jogador"],
        "status": "Você comprou uma peça do monte.",
        "fim_de_jogo": False,
        "quantidade_monte": len(monte),
    }


@app.post("/partidas/jogar", response_model=StatusPartidaResponse)
def jogar_peca(payload: JogarPecaPayload):
    if payload.id_partida not in PARTIDAS_ATIVAS:
        raise HTTPException(status_code=404, detail="Partida não encontrada ou expirada.")

    partida = PARTIDAS_ATIVAS[payload.id_partida]
    if partida["fim_de_jogo"]:
        raise HTTPException(status_code=400, detail="Esta partida já foi encerrada.")

    peca_jogador = next(
        (p for p in partida["mao_jogador"] if p["id_peca"] == payload.id_peca), None
    )
    if not peca_jogador:
        raise HTTPException(status_code=400, detail="Você não possui essa peça na sua mão.")

    mesa = partida["mesa"]
    ponta_esquerda_mesa = mesa[0]
    ponta_direita_mesa = mesa[-1]

    jogada_valida = False
    nova_peca_mesa = peca_jogador.copy()

    if payload.ponta == "esquerda":
        if peca_jogador["validador_direito"] == ponta_esquerda_mesa["validador_esquerdo"]:
            mesa.insert(0, nova_peca_mesa)
            jogada_valida = True

    elif payload.ponta == "direita":
        if peca_jogador["validador_esquerdo"] == ponta_direita_mesa["validador_direito"]:
            mesa.append(nova_peca_mesa)
            jogada_valida = True

    if not jogada_valida:
        raise HTTPException(
            status_code=422,
            detail="Combinação química incorreta! Tente outra peça ou extremidade.",
        )

    partida["mao_jogador"].remove(peca_jogador)

    # Verifica vitória do jogador
    if len(partida["mao_jogador"]) == 0:
        partida["fim_de_jogo"] = True
        partida["resultado"] = "Vitória do Jogador"
        return {
            "id_partida": payload.id_partida,
            "mesa": mesa,
            "mao_jogador": partida["mao_jogador"],
            "status": "Você venceu! Todas as peças foram descartadas.",
            "fim_de_jogo": True,
            "quantidade_monte": len(partida["monte_compras"]),
        }

    # Delega o turno do bot para a função centralizada
    return _processar_turno_bot(payload.id_partida, partida)


# [CORREÇÃO BUG 1] Novo endpoint para o jogador passar a vez quando não tem jogada válida.
# Antes, não existia essa rota: se o monte estivesse vazio e o jogador não tivesse
# encaixes, o app entrava em loop infinito de erros 422. Agora o jogador passa
# a vez formalmente, o bot joga normalmente e o trancamento é detectado corretamente.
@app.post("/partidas/passar", response_model=StatusPartidaResponse)
def passar_vez(payload: PassarVezPayload):
    if payload.id_partida not in PARTIDAS_ATIVAS:
        raise HTTPException(status_code=404, detail="Partida não encontrada.")

    partida = PARTIDAS_ATIVAS[payload.id_partida]
    if partida["fim_de_jogo"]:
        raise HTTPException(status_code=400, detail="Esta partida já foi encerrada.")

    mesa = partida["mesa"]

    # Garante que o jogador realmente não tem jogada disponível.
    # Isso impede que o aluno use "passar" como atalho quando ainda pode jogar.
    if _verificar_jogadas_possiveis(partida["mao_jogador"], mesa):
        raise HTTPException(
            status_code=400,
            detail="Você ainda possui jogadas possíveis! Tente encaixar uma peça.",
        )

    # Garante que o monte também está esgotado.
    # Se ainda há peças no monte, o jogador deve comprar antes de passar.
    if len(partida["monte_compras"]) > 0:
        raise HTTPException(
            status_code=400,
            detail="Ainda há peças no monte. Compre uma peça antes de passar a vez!",
        )

    # Jogador passa a vez legitimamente → processa o turno do bot
    return _processar_turno_bot(payload.id_partida, partida)