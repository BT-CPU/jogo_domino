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
    "ssl_disabled": False,
}

def get_connection():
    return mysql.connector.connect(**DB_CONFIG)

# ─── MODELS ─────────────────────────────────────────────────────────────────
class CadastroUsuario(BaseModel):
    nome: str
    email: EmailStr
    senha: str
    aceite_lgpd: bool
    perfil: str = 'aluno'  # 'aluno' ou 'professor'

# ─── ROTAS ──────────────────────────────────────────────────────────────────

@app.get("/")
def root():
    return {"status": "API Dominó da Química online"}


@app.post("/usuarios", status_code=201)
def cadastrar_usuario(dados: CadastroUsuario):
    if not dados.aceite_lgpd:
        raise HTTPException(status_code=400, detail="Aceite da LGPD é obrigatório.")

    if dados.perfil not in ('aluno', 'professor'):
        raise HTTPException(status_code=400, detail="Perfil inválido. Use 'aluno' ou 'professor'.")

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
        perfil_label = 'Professor' if dados.perfil == 'professor' else 'Aluno'
        return {"id_usuario": novo_id, "mensagem": f"{perfil_label} cadastrado com sucesso."}
    except mysql.connector.IntegrityError:
        raise HTTPException(status_code=409, detail="E-mail já cadastrado.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


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
        for u in usuarios:
            if u["data_cadastro"]:
                u["data_cadastro"] = u["data_cadastro"].strftime("%d/%m/%Y %H:%M")
        return usuarios
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/usuarios/{id_usuario}", status_code=200)
def excluir_usuario(id_usuario: int):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(
            "DELETE FROM tb_usuario WHERE id_usuario = %s",
            (id_usuario,),
        )
        conn.commit()
        affected = cursor.rowcount
        cursor.close()
        conn.close()
        if affected == 0:
            raise HTTPException(status_code=404, detail="Usuário não encontrado.")
        return {"mensagem": "Usuário excluído com sucesso."}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))