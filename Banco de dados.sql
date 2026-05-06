USE defaultdb;

-- Armazena os dados de acesso e controle de perfil (aluno/professor).
-- O campo 'aceite_lgpd' registra a permissão para armazenamento dos dados.
CREATE TABLE tb_usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    perfil ENUM('aluno', 'professor') NOT NULL DEFAULT 'aluno',
    aceite_lgpd BOOLEAN NOT NULL DEFAULT FALSE, 
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Agrupa alunos em salas específicas (ex: 1º Ano A).
-- Utilizado para organizar os relatórios de desempenho vistos pelos professores.
CREATE TABLE tb_turma (
    id_turma INT AUTO_INCREMENT PRIMARY KEY,
    nome_turma VARCHAR(50) NOT NULL,
    id_professor INT NOT NULL,
    FOREIGN KEY (id_professor) REFERENCES tb_usuario(id_usuario) ON DELETE CASCADE
);

-- Relaciona um aluno à sua respectiva turma.
CREATE TABLE tb_aluno_turma (
    id_usuario INT NOT NULL,
    id_turma INT NOT NULL,
    PRIMARY KEY (id_usuario, id_turma),
    FOREIGN KEY (id_usuario) REFERENCES tb_usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_turma) REFERENCES tb_turma(id_turma) ON DELETE CASCADE
);

-- Base de dados do conteúdo de química.
-- Fornece os valores exatos para preencher e validar as peças do dominó.
CREATE TABLE tb_composto (
    id_composto INT AUTO_INCREMENT PRIMARY KEY,
    formula VARCHAR(50) NOT NULL UNIQUE,  
    nome_oficial VARCHAR(100) NOT NULL,   
    funcao ENUM('Ácido', 'Base', 'Sal', 'Óxido') NOT NULL,
    propriedade TEXT                      
);

-- Índice criado para otimizar e acelerar a busca de compostos pela função inorgânica.
CREATE INDEX idx_funcao ON tb_composto(funcao);

-- Registra o histórico e os resultados de cada sessão de jogo.
-- Alimenta a tela de relatórios do aplicativo com tempo e pontuação.
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

-- Insere as peças utilizadas como exemplo na tela "Como Jogar".
INSERT INTO tb_composto (formula, nome_oficial, funcao, propriedade) VALUES 
('H2SO4', 'Ácido Sulfúrico', 'Ácido', 'Em solução aquosa ioniza e libera íons H+'),
('NaOH', 'Hidróxido de Sódio', 'Base', 'Apresenta o grupo hidroxila (OH-) e dissocia em água');
