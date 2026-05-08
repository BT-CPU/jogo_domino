from __future__ import annotations

import random
from dataclasses import dataclass
from typing import Any
from uuid import uuid4

import bcrypt
import mysql.connector
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr

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


def get_connection():
    return mysql.connector.connect(**DB_CONFIG)


class CadastroAluno(BaseModel):
    nome: str
    email: EmailStr
    senha: str
    aceite_lgpd: bool


class IniciarPartidaPayload(BaseModel):
    id_usuario: int | None = None
    nivel_dificuldade: int


class JogadaPayload(BaseModel):
    estado: dict[str, Any]
    peca: dict[str, Any]


class FinalizarPartidaPayload(BaseModel):
    id_usuario: int | None = None
    nivel_dificuldade: int
    tempo_segundos: int
    qtd_acertos: int
    qtd_erros: int


@dataclass(frozen=True)
class ConteudoQuimico:
    formula: str
    funcao: str
    classificacao: str
    propriedade: str


@dataclass(frozen=True)
class Compatibilidade:
    origem: str
    destino: str


CONTEUDOS: list[ConteudoQuimico] = [
    ConteudoQuimico("HCl", "Acido", "Acido", "Libera H+ em agua"),
    ConteudoQuimico("H2SO4", "Acido", "Acido", "Ioniza e forma H+"),
    ConteudoQuimico("HNO3", "Acido", "Acido", "Acido forte em agua"),
    ConteudoQuimico("NaOH", "Base", "Base", "Libera OH- em agua"),
    ConteudoQuimico("KOH", "Base", "Base", "Hidroxila em solucao"),
    ConteudoQuimico("Ca(OH)2", "Base", "Base", "Base ionica com OH-"),
    ConteudoQuimico("NaCl", "Sal", "Sal", "Resulta de neutralizacao"),
    ConteudoQuimico(
        "KNO3", "Sal", "Sal", "Composto ionico derivado de acido e base"
    ),
    ConteudoQuimico("CaCO3", "Sal", "Sal", "Sal de carbonato"),
    ConteudoQuimico("CO2", "Oxido", "Oxido acido", "Oxido de ametal"),
    ConteudoQuimico(
        "SO3", "Oxido", "Oxido acido", "Oxido que forma acido em agua"
    ),
    ConteudoQuimico("CaO", "Oxido", "Oxido basico", "Oxido de metal"),
    ConteudoQuimico("Na2O", "Oxido", "Oxido basico", "Oxido metalico basico"),
]

COMPATIBILIDADES: list[Compatibilidade] = [
    Compatibilidade("Acido", "Base"),
    Compatibilidade("Base", "Acido"),
    Compatibilidade("Acido", "Oxido basico"),
    Compatibilidade("Oxido basico", "Acido"),
    Compatibilidade("Base", "Oxido acido"),
    Compatibilidade("Oxido acido", "Base"),
]


def dificuldade_titulo(nivel: int) -> str:
    return {
        1: "Nivel 1",
        2: "Nivel 2",
        3: "Nivel 3",
    }.get(nivel, "Nivel 1")


def dificuldade_descricao(nivel: int) -> str:
    return {
        1: "Formula ↔ Funcao",
        2: "Propriedades ↔ Classificacao",
        3: "Classificacao ↔ Reacao",
    }.get(nivel, "Formula ↔ Funcao")


def lado(tipo: str, valor: str) -> dict[str, str]:
    return {
        "tipo": tipo,
        "valor": valor,
    }


def peca(identificador: str, esquerda: dict[str, str], direita: dict[str, str]):
    return {
        "id": identificador,
        "esquerda": esquerda,
        "direita": direita,
    }


def posicionada(peca_jogo: dict[str, Any], origem: str) -> dict[str, Any]:
    return {
        "id": f"{peca_jogo['id']}-{origem}",
        "esquerda": peca_jogo["esquerda"],
        "direita": peca_jogo["direita"],
        "origem": origem,
    }


def invertida(peca_jogo: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": peca_jogo["id"],
        "esquerda": peca_jogo["direita"],
        "direita": peca_jogo["esquerda"],
    }


def build_pool(nivel_dificuldade: int) -> list[dict[str, Any]]:
    if nivel_dificuldade == 1:
        return [
            peca(
                f"d1-{conteudo.formula}",
                lado("formula", conteudo.formula),
                lado("funcao", conteudo.funcao),
            )
            for conteudo in CONTEUDOS
        ]

    if nivel_dificuldade == 2:
        return [
            peca(
                f"d2-{idx}",
                lado("propriedade", conteudo.propriedade),
                lado("classificacao", conteudo.classificacao),
            )
            for idx, conteudo in enumerate(CONTEUDOS, start=1)
        ]

    return [
        peca(
            f"d3-{idx}",
            lado("classificacao", compatibilidade.origem),
            lado("classificacao", compatibilidade.destino),
        )
        for idx, compatibilidade in enumerate(COMPATIBILIDADES, start=1)
    ]


def sao_compativeis(
    nivel_dificuldade: int,
    primeiro: dict[str, str],
    segundo: dict[str, str],
) -> bool:
    if nivel_dificuldade == 1:
        formula = primeiro["valor"] if primeiro["tipo"] == "formula" else None
        if segundo["tipo"] == "formula":
            formula = segundo["valor"]
        funcao = primeiro["valor"] if primeiro["tipo"] == "funcao" else None
        if segundo["tipo"] == "funcao":
            funcao = segundo["valor"]
        if formula is None or funcao is None:
            return False
        return any(
            conteudo.formula == formula and conteudo.funcao == funcao
            for conteudo in CONTEUDOS
        )

    if nivel_dificuldade == 2:
        propriedade = (
            primeiro["valor"] if primeiro["tipo"] == "propriedade" else None
        )
        if segundo["tipo"] == "propriedade":
            propriedade = segundo["valor"]
        classificacao = (
            primeiro["valor"] if primeiro["tipo"] == "classificacao" else None
        )
        if segundo["tipo"] == "classificacao":
            classificacao = segundo["valor"]
        if propriedade is None or classificacao is None:
            return False
        return any(
            conteudo.propriedade == propriedade
            and conteudo.classificacao == classificacao
            for conteudo in CONTEUDOS
        )

    if primeiro["tipo"] != "classificacao" or segundo["tipo"] != "classificacao":
        return False

    return any(
        compatibilidade.origem == primeiro["valor"]
        and compatibilidade.destino == segundo["valor"]
        for compatibilidade in COMPATIBILIDADES
    ) or any(
        compatibilidade.origem == segundo["valor"]
        and compatibilidade.destino == primeiro["valor"]
        for compatibilidade in COMPATIBILIDADES
    )


def posicionar_peca(
    nivel_dificuldade: int,
    ponta_ativa: dict[str, str],
    peca_jogo: dict[str, Any],
    origem: str,
) -> dict[str, Any] | None:
    if sao_compativeis(nivel_dificuldade, ponta_ativa, peca_jogo["esquerda"]):
        return {
            "id": f"{peca_jogo['id']}-{origem}",
            "esquerda": peca_jogo["esquerda"],
            "direita": peca_jogo["direita"],
            "origem": origem,
        }
    if sao_compativeis(nivel_dificuldade, ponta_ativa, peca_jogo["direita"]):
        return {
            "id": f"{peca_jogo['id']}-{origem}",
            "esquerda": peca_jogo["direita"],
            "direita": peca_jogo["esquerda"],
            "origem": origem,
        }
    return None


def pode_conectar(
    nivel_dificuldade: int,
    ponta_ativa: dict[str, str],
    peca_jogo: dict[str, Any],
) -> bool:
    return posicionar_peca(nivel_dificuldade, ponta_ativa, peca_jogo, "teste") is not None


def escolher_inicio(
    nivel_dificuldade: int,
    mao_jogador: list[dict[str, Any]],
    candidatas: list[dict[str, Any]],
) -> dict[str, Any]:
    candidatas_baralhadas = candidatas[:]
    random.shuffle(candidatas_baralhadas)
    for candidata in candidatas_baralhadas:
        if any(
            pode_conectar(nivel_dificuldade, candidata["direita"], item)
            for item in mao_jogador
        ):
            return candidata
        candidata_invertida = invertida(candidata)
        if any(
            pode_conectar(nivel_dificuldade, candidata_invertida["direita"], item)
            for item in mao_jogador
        ):
            return candidata_invertida
    return candidatas_baralhadas[0]


def gerar_jogada_bot(
    nivel_dificuldade: int,
    ponta_ativa: dict[str, str],
    mao_jogador_restante: list[dict[str, Any]],
) -> dict[str, Any] | None:
    candidatas: list[tuple[dict[str, Any], int]] = []
    fallback: list[dict[str, Any]] = []

    for item in build_pool(nivel_dificuldade):
        posicionada_bot = posicionar_peca(
            nivel_dificuldade, ponta_ativa, item, "bot"
        )
        if posicionada_bot is None:
            continue

        fallback.append(posicionada_bot)

        conexoes_futuras = sum(
            1
            for peca_jogador in mao_jogador_restante
            if pode_conectar(
                nivel_dificuldade, posicionada_bot["direita"], peca_jogador
            )
        )

        if conexoes_futuras > 0:
            candidatas.append((posicionada_bot, conexoes_futuras))

    if candidatas:
        melhor_pontuacao = max(pontuacao for _, pontuacao in candidatas)
        melhores = [
            peca_bot
            for peca_bot, pontuacao in candidatas
            if pontuacao == melhor_pontuacao
        ]
        return random.choice(melhores)
    if fallback:
        return random.choice(fallback)
    return None


def atualizar_estado_base(
    *,
    id_usuario: int | None,
    nivel_dificuldade: int,
    ponta_ativa: dict[str, str],
    mao_jogador: list[dict[str, Any]],
    tabuleiro: list[dict[str, Any]],
    qtd_acertos: int = 0,
    qtd_erros: int = 0,
    tempo_segundos: int = 0,
    turno_atual: str = "jogador",
    status: str = "emAndamento",
) -> dict[str, Any]:
    return {
        "id_usuario": id_usuario,
        "dificuldade": nivel_dificuldade,
        "turno_atual": turno_atual,
        "status": status,
        "qtd_acertos": qtd_acertos,
        "qtd_erros": qtd_erros,
        "tempo_segundos": tempo_segundos,
        "ponta_ativa": ponta_ativa,
        "mao_jogador": mao_jogador,
        "tabuleiro": tabuleiro,
    }


@app.post("/alunos", status_code=201)
def cadastrar_aluno(dados: CadastroAluno):
    if not dados.aceite_lgpd:
        raise HTTPException(status_code=400, detail="Aceite da LGPD e obrigatorio.")

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
        raise HTTPException(status_code=409, detail="E-mail ja cadastrado.")
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
        for aluno in alunos:
            if aluno["data_cadastro"]:
                aluno["data_cadastro"] = aluno["data_cadastro"].strftime("%d/%m/%Y %H:%M")
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
            raise HTTPException(status_code=404, detail="Aluno nao encontrado.")
        return {"mensagem": "Aluno excluido com sucesso."}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/partidas/iniciar")
def iniciar_partida(payload: IniciarPartidaPayload):
    pool = build_pool(payload.nivel_dificuldade)
    random.shuffle(pool)
    tamanho_mao = min(5, max(3, len(pool) // 2))
    mao_jogador = pool[:tamanho_mao]
    restantes = pool[tamanho_mao:] or pool[:]
    inicio = escolher_inicio(payload.nivel_dificuldade, mao_jogador, restantes)
    return atualizar_estado_base(
        id_usuario=payload.id_usuario,
        nivel_dificuldade=payload.nivel_dificuldade,
        ponta_ativa=inicio["direita"],
        mao_jogador=mao_jogador,
        tabuleiro=[posicionada(inicio, "inicial")],
    )


@app.post("/partidas/jogada")
def jogar_peca(payload: JogadaPayload):
    estado = payload.estado
    peca_jogada = payload.peca
    nivel_dificuldade = int(estado["dificuldade"])

    if estado["status"] == "finalizada":
        return {
            "jogada_valida": False,
            "estado": estado,
            "mensagem": "A partida ja foi encerrada.",
            "peca_bot": None,
        }

    posicionada_jogador = posicionar_peca(
        nivel_dificuldade,
        estado["ponta_ativa"],
        peca_jogada,
        "jogador",
    )

    if posicionada_jogador is None:
        estado["qtd_erros"] = int(estado["qtd_erros"]) + 1
        return {
            "jogada_valida": False,
            "estado": estado,
            "mensagem": "Conexao incorreta. Tente outra peca.",
            "peca_bot": None,
        }

    nova_mao = [
        item for item in estado["mao_jogador"] if item["id"] != peca_jogada["id"]
    ]
    novo_tabuleiro = [*estado["tabuleiro"], posicionada_jogador]

    novo_estado = atualizar_estado_base(
        id_usuario=estado.get("id_usuario"),
        nivel_dificuldade=nivel_dificuldade,
        ponta_ativa=posicionada_jogador["direita"],
        mao_jogador=nova_mao,
        tabuleiro=novo_tabuleiro,
        qtd_acertos=int(estado["qtd_acertos"]) + 1,
        qtd_erros=int(estado["qtd_erros"]),
        tempo_segundos=int(estado["tempo_segundos"]),
        turno_atual="bot",
        status="emAndamento",
    )

    if not nova_mao:
        novo_estado["status"] = "finalizada"
        novo_estado["turno_atual"] = "jogador"
        return {
            "jogada_valida": True,
            "estado": novo_estado,
            "mensagem": "Voce esvaziou a mao e concluiu a partida!",
            "peca_bot": None,
        }

    peca_bot = gerar_jogada_bot(
        nivel_dificuldade,
        novo_estado["ponta_ativa"],
        nova_mao,
    )

    if peca_bot is None:
        novo_estado["turno_atual"] = "jogador"
        return {
            "jogada_valida": True,
            "estado": novo_estado,
            "mensagem": "Jogada correta. O bot nao encontrou resposta e voce pode usar pecas esgotadas.",
            "peca_bot": None,
        }

    novo_estado["tabuleiro"].append(peca_bot)
    novo_estado["ponta_ativa"] = peca_bot["direita"]
    novo_estado["turno_atual"] = "jogador"

    return {
        "jogada_valida": True,
        "estado": novo_estado,
        "mensagem": "Jogada correta. O bot respondeu com uma peca compativel.",
        "peca_bot": peca_bot,
    }


@app.post("/partidas/finalizar")
def finalizar_partida(payload: FinalizarPartidaPayload):
    if payload.id_usuario is None:
        return {"mensagem": "Partida finalizada sem persistencia de usuario."}

    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO tb_partida (
                id_usuario,
                nivel_dificuldade,
                tempo_segundos,
                qtd_acertos,
                qtd_erros
            ) VALUES (%s, %s, %s, %s, %s)
            """,
            (
                payload.id_usuario,
                payload.nivel_dificuldade,
                payload.tempo_segundos,
                payload.qtd_acertos,
                payload.qtd_erros,
            ),
        )
        conn.commit()
        partida_id = cursor.lastrowid
        cursor.close()
        conn.close()
        return {
            "id_partida": partida_id,
            "mensagem": "Partida registrada com sucesso.",
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
