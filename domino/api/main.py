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

class PecaDomino(BaseModel):
    id_peca: int
    visivel_esquerdo: str  # O que aparece na tela (ex: "HCl")
    visivel_direito: str   # O que aparece na tela (ex: "Ácido", "Nitrato de Sódio")
    validador_esquerdo: int # ID da classificação (1 a 4) para o back checar a química
    validador_direito: int  # ID da classificação (1 a 4) para o back checar a química

class StatusPartidaResponse(BaseModel):
    id_partida: str  # <--- ADICIONADO AQUI
    mesa: list[PecaDomino]          
    mao_jogador: list[PecaDomino]    
    status: str
    fim_de_jogo: bool

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

def _gerar_corrente_domino(nivel: int) -> list:
    """
    Busca os dados no banco e monta uma corrente fechada de 40 peças válidas.
    Cada peça é um dicionário com: id_peca, esquerdo, direito e as chaves de validação.
    """
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    
    # 1. Buscar dados do banco dependendo do nível
    cursor.execute("SELECT id_composto, formula, nome, id_classificacao FROM tb_composto")
    compostos = cursor.fetchall()
    
    # Agrupa compostos por classificação para facilitar o sorteio equilibrado
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

    # 2. Criar uma sequência lógica e equilibrada de 40 encaixes químicos (IDs de classificação)
    # Ex: [1, 2, 2, 4, 4, 3, 3, 1...] onde cada par adjacente (e as pontas) formam uma peça
    sequencia_classes = []
    classes = [1, 2, 3, 4]
    
    # Garante distribuição perfeita: 10 aparições para cada uma das 4 funções nas pontas das peças
    for _ in range(10):
        random.shuffle(classes)
        sequencia_classes.extend(classes)
        
    # Duplica os elementos para criar os encaixes internos das peças de dominó
    # Sequência vira: [C1, C1, C2, C2, C3, C3...] -> Peça 1: (C1|C1), Peça 2: (C2|C2)... Não queremos duplos perfeitos.
    # Vamos rotacionar a lista de correspondência para cruzar os dados de forma que esquerdo != direito
    sequencia_esquerda = sequencia_classes.copy()
    sequencia_direita = sequencia_classes[1:] + [sequencia_classes[0]] # Rotaciona 1 elemento para o lado
    
    pecas_geradas = []
    id_peca_tracker = 1
    
    # 3. Construir as peças textuais com base no nível técnico selecionado
    for cl_esq, cl_dir in zip(sequencia_esquerda, sequencia_direita):
        # Sorteia elementos do banco sem repetir na mesma peça
        comp_esq = random.choice(compostos_por_classe[cl_esq])
        
        # Define o que vai escrito no lado Esquerdo (Sempre Fórmula)
        conteudo_esq = comp_esq["formula"]
        
        # Define o que vai escrito no lado Direito dependendo da Dificuldade
        if nivel == 1:
            conteudo_dir = classificacoes_nomes[cl_dir]
        elif nivel == 2:
            # Nível 2: Fórmula liga com Nome Exato do Composto correspondente.
            # Para a peça não ser um espelho estático do mesmo composto (o que travaria o dominó),
            # o lado direito traz o Nome de OUTRO composto pertencente à classe da direita.
            comp_dir = random.choice(compostos_por_classe[cl_dir])
            conteudo_dir = comp_dir["nome"]
        else: # nivel == 3
            conteudo_dir = random.choice(propriedades_por_classe[cl_dir])
            
        pecas_geradas.append({
            "id_peca": id_peca_tracker,
            "visivel_esquerdo": conteudo_esq,
            "visivel_direito": conteudo_dir,
            "validador_esquerdo": cl_esq, # ID Químico da Fórmula
            "validador_direito": cl_dir    # ID Químico do Conceito/Nome/Propriedade
        })
        id_peca_tracker += 1
        
    return pecas_geradas


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
    # ... todo o código que já fizemos continua igual ...
    if payload.nivel_dificuldade not in (1, 2, 3):
        raise HTTPException(status_code=400, detail="Nível de dificuldade inválido.")
        
    # 1. Gera as 40 peças amarradas pela engenharia reversa
    todas_pecas = _gerar_corrente_domino(payload.nivel_dificuldade)
    
    # 2. Distribuição alternada para garantir o fechamento matemático
    # Ímpares para o Bot, Pares para o Jogador
    mao_bot = [todas_pecas[i] for i in range(len(todas_pecas)) if i % 2 == 0]
    mao_jogador = [todas_pecas[i] for i in range(len(todas_pecas)) if i % 2 != 0]
    
    # 3. O Bot inicia o jogo sacrificando a sua primeira peça na mesa
    peca_inicial_bot = mao_bot.pop(0)
    mesa = [peca_inicial_bot]
    
    # Embaralha as mãos individualmente para o jogador ter o desafio de procurar o encaixe
    random.shuffle(mao_jogador)
    random.shuffle(mao_bot)
    
    # 4. Salva o estado da partida na memória do servidor usando um ID único string
    id_partida = f"partida_{payload.id_usuario}_{int(datetime.now().timestamp())}"
    PARTIDAS_ATIVAS[id_partida] = {
        "id_usuario": payload.id_usuario,
        "nivel": payload.nivel_dificuldade,
        "mesa": mesa,
        "mao_jogador": mao_jogador,
        "mao_bot": mao_bot,
        "fim_de_jogo": False,
        "resultado": None
    }
    
    # 5. Retorna para o Flutter (Apenas a mão do jogador e a mesa são expostas!)
    return {
        "id_partida": id_partida,
        "mesa": mesa,
        "mao_jogador": mao_jogador,
        "status": "Seu turno",
        "fim_de_jogo": False
    }

@app.post("/partidas/jogar", response_model=StatusPartidaResponse)
def jogar_peca(payload: JogarPecaPayload):
    # Verifica se a partida existe na memória
    if payload.id_partida not in PARTIDAS_ATIVAS:
        raise HTTPException(status_code=404, detail="Partida não encontrada ou expirada.")
        
    partida = PARTIDAS_ATIVAS[payload.id_partida]
    if partida["fim_de_jogo"]:
        raise HTTPException(status_code=400, detail="Esta partida já foi encerrada.")

    # 1. Localizar a peça na mão do jogador
    peca_jogador = next((p for p in partida["mao_jogador"] if p["id_peca"] == payload.id_peca), None)
    if not peca_jogador:
        raise HTTPException(status_code=400, detail="Você não possui essa peça na sua mão.")
        
    mesa = partida["mesa"]
    ponta_esquerda_mesa = mesa[0]
    ponta_direita_mesa = mesa[-1]
    
    jogada_valida = False
    nova_peca_mesa = peca_jogador.copy()
    
    # 2. Validação da Jogada Química do Aluno
    if payload.ponta == "esquerda":
        # Direito da peça do jogador se conecta com o Esquerdo da mesa
        if peca_jogador["validador_direito"] == ponta_esquerda_mesa["validador_esquerdo"]:
            mesa.insert(0, nova_peca_mesa)
            jogada_valida = True
            
    elif payload.ponta == "direita":
        # Esquerdo da peça do jogador se conecta com o Direito da mesa
        if peca_jogador["validador_esquerdo"] == ponta_direita_mesa["validador_direito"]:
            mesa.append(nova_peca_mesa)
            jogada_valida = True

    if not jogada_valida:
        raise HTTPException(status_code=422, detail="Combinação química incorreta! Tente outra peça ou outra extremidade.")

    # Remove a peça jogada com sucesso da mão do jogador
    partida["mao_jogador"].remove(peca_jogador)

    # 3. Checa se o Jogador venceu imediatamente (Mão zerada)
    if len(partida["mao_jogador"]) == 0:
        partida["fim_de_jogo"] = True
        partida["resultado"] = "Vitória do Jogador"
        return {
            "id_partida": payload.id_partida,
            "mesa": mesa,
            "mao_jogador": partida["mao_jogador"],
            "status": "Você venceu! Todas as peças foram descartadas.",
            "fim_de_jogo": True
        }

    # 4. Turno do Bot Automatizado
    ponta_esquerda_mesa = mesa[0]
    ponta_direita_mesa = mesa[-1]
    peca_bot_escolhida = None
    ponta_bot_escolhida = ""

    # O bot varre a mão dele procurando um encaixe válido
    for p_bot in partida["mao_bot"]:
        if p_bot["validador_direito"] == ponta_esquerda_mesa["validador_esquerdo"]:
            peca_bot_escolhida = p_bot
            ponta_bot_escolhida = "esquerda"
            break
        elif p_bot["validador_esquerdo"] == ponta_direita_mesa["validador_direito"]:
            peca_bot_escolhida = p_bot
            ponta_bot_escolhida = "direita"
            break

    # Se o Bot achou uma jogada
    if peca_bot_escolhida:
        partida["mao_bot"].remove(peca_bot_escolhida)
        if ponta_bot_escolhida == "esquerda":
            mesa.insert(0, peca_bot_escolhida)
        else:
            mesa.append(peca_bot_escolhida)
        status_bot = f"O Bot jogou uma peça na {ponta_bot_escolhida}. Sua vez!"
    else:
        status_bot = "O Bot não encontrou combinação química e passou a vez. Sua vez!"

    # 5. Checa se o Bot zerou a mão
    if len(partida["mao_bot"]) == 0:
        partida["fim_de_jogo"] = True
        partida["resultado"] = "Vitória do Bot"
        return {
            "id_partida": payload.id_partida,
            "mesa": mesa,
            "mao_jogador": partida["mao_jogador"],
            "status": "O Bot fechou o jogo antes de você!",
            "fim_de_jogo": True
        }

    # Retorna o novo estado estável da mesa após a jogada
    return {
        "id_partida": payload.id_partida,
        "mesa": mesa,
        "mao_jogador": partida["mao_jogador"],
        "status": status_bot,
        "fim_de_jogo": False
    }