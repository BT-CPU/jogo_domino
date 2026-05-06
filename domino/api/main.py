from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
import mysql.connector
import bcrypt

app = FastAPI(title="Dominó da Química API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── CONFIGURAÇÃO DO BANCO (Aiven MySQL) ────────────────────────────────────
DB_CONFIG = {
    "host":         "mysql-17b3ac90-guitursi-f0c2.j.aivencloud.com",
    "port":         20062,
    "user":         "avnadmin",
    "password":     "AVNS__zDss8p43pIUQo8PyRf",
    "database":     "defaultdb",
    "ssl_disabled": False,  # SSL obrigatório no Aiven
}

def get_connection():
    return mysql.connector.connect(**DB_CONFIG)

# ─── MODELS ─────────────────────────────────────────────────────────────────
class CadastroAluno(BaseModel):
    nome: str
    email: EmailStr
    senha: str
    aceite_lgpd: bool

# ─── ROTAS ──────────────────────────────────────────────────────────────────

@app.post("/alunos", status_code=201)
def cadastrar_aluno(dados: CadastroAluno):
    if not dados.aceite_lgpd:
        raise HTTPException(status_code=400, detail="Aceite da LGPD é obrigatório.")

    senha_hash = bcrypt.hashpw(dados.senha.encode(), bcrypt.gensalt()).decode()

    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO tb_usuario (nome, email, senha_hash, perfil, aceite_lgpd)
            VALUES (%s, %s, %s, 'aluno', %s)
            """,
            (dados.nome, dados.email, senha_hash, dados.aceite_lgpd),
        )
        conn.commit()
        novo_id = cursor.lastrowid
        cursor.close()
        conn.close()
        return {"id_usuario": novo_id, "mensagem": "Aluno cadastrado com sucesso."}
    except mysql.connector.IntegrityError:
        raise HTTPException(status_code=409, detail="E-mail já cadastrado.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/alunos")
def listar_alunos():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT id_usuario, nome, email, data_cadastro
            FROM tb_usuario
            WHERE perfil = 'aluno'
            ORDER BY data_cadastro DESC
            """
        )
        alunos = cursor.fetchall()
        cursor.close()
        conn.close()
        # Converte datetime para string para serialização JSON
        for a in alunos:
            if a["data_cadastro"]:
                a["data_cadastro"] = a["data_cadastro"].strftime("%d/%m/%Y %H:%M")
        return alunos
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/alunos/{id_usuario}", status_code=200)
def excluir_aluno(id_usuario: int):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(
            "DELETE FROM tb_usuario WHERE id_usuario = %s AND perfil = 'aluno'",
            (id_usuario,),
        )
        conn.commit()
        affected = cursor.rowcount
        cursor.close()
        conn.close()
        if affected == 0:
            raise HTTPException(status_code=404, detail="Aluno não encontrado.")
        return {"mensagem": "Aluno excluído com sucesso."}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
