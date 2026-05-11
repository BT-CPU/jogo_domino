USE defaultdb;

-- Armazena os dados de acesso e controle de perfil (aluno/professor).
-- O campo 'aceite_lgpd' registra a permissao para armazenamento dos dados.
CREATE TABLE tb_usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    perfil ENUM('aluno', 'professor') NOT NULL DEFAULT 'aluno',
    aceite_lgpd BOOLEAN NOT NULL DEFAULT FALSE,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Agrupa alunos em salas especificas (ex: 1 Ano A).
-- Utilizado para organizar os relatorios de desempenho vistos pelos professores.
CREATE TABLE tb_turma (
    id_turma INT AUTO_INCREMENT PRIMARY KEY,
    nome_turma VARCHAR(50) NOT NULL,
    id_professor INT NOT NULL,
    FOREIGN KEY (id_professor) REFERENCES tb_usuario(id_usuario) ON DELETE CASCADE
);

-- Relaciona um aluno a sua respectiva turma.
CREATE TABLE tb_aluno_turma (
    id_usuario INT NOT NULL,
    id_turma INT NOT NULL,
    PRIMARY KEY (id_usuario, id_turma),
    FOREIGN KEY (id_usuario) REFERENCES tb_usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_turma) REFERENCES tb_turma(id_turma) ON DELETE CASCADE
);

CREATE INDEX idx_turma_professor ON tb_turma(id_professor);
CREATE INDEX idx_aluno_turma_usuario ON tb_aluno_turma(id_usuario);
CREATE INDEX idx_aluno_turma_turma ON tb_aluno_turma(id_turma);

-- Registra o historico e os resultados de cada sessao de jogo.
-- Alimenta a tela de relatorios do aplicativo com tempo, acertos e erros.
CREATE TABLE tb_partida (
    id_partida INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    nivel_dificuldade INT NOT NULL,
    tempo_segundos INT DEFAULT 0,
    qtd_acertos INT DEFAULT 0,
    qtd_erros INT DEFAULT 0,
    data_partida DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES tb_usuario(id_usuario) ON DELETE CASCADE
);

CREATE INDEX idx_partida_usuario_data ON tb_partida(id_usuario, data_partida DESC);
CREATE INDEX idx_partida_usuario_tempo ON tb_partida(id_usuario, tempo_segundos);
