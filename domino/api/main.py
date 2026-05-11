from datetime import datetime

import mysql.connector
from mysql.connector import pooling
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr

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
