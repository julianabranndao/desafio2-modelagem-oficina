-- =============================================
-- Desafio 2 - Oficina Mecânica (Modelo Relacional)
-- Versão Corrigida (VIEW compatível com MySQL 8.0)
-- =============================================

DROP DATABASE IF EXISTS oficina;
CREATE DATABASE oficina DEFAULT CHARACTER SET utf8mb4;
USE oficina;

CREATE TABLE cliente (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  tipo ENUM('PF','PJ') NOT NULL,
  nome_razao VARCHAR(120) NOT NULL,
  cpf CHAR(11) NULL UNIQUE,
  cnpj CHAR(14) NULL UNIQUE,
  endereco VARCHAR(150),
  telefone VARCHAR(20),
  email VARCHAR(100),
  CONSTRAINT ck_cliente_exclusivo CHECK (
    (tipo = 'PF' AND cpf IS NOT NULL AND cnpj IS NULL) OR
    (tipo = 'PJ' AND cnpj IS NOT NULL AND cpf IS NULL)
  )
) ENGINE=InnoDB;

CREATE TABLE veiculo (
  id_veiculo INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT NOT NULL,
  placa VARCHAR(10) NOT NULL UNIQUE,
  marca VARCHAR(45),
  modelo VARCHAR(45),
  ano SMALLINT,
  CONSTRAINT fk_veiculo_cliente
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
) ENGINE=InnoDB;

CREATE TABLE mecanico (
  id_mecanico INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  endereco VARCHAR(150),
  especialidade VARCHAR(60) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE equipe (
  id_equipe INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(60) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE equipe_mecanico (
  id_equipe INT NOT NULL,
  id_mecanico INT NOT NULL,
  PRIMARY KEY (id_equipe, id_mecanico),
  CONSTRAINT fk_em_equipe
    FOREIGN KEY (id_equipe) REFERENCES equipe(id_equipe),
  CONSTRAINT fk_em_mecanico
    FOREIGN KEY (id_mecanico) REFERENCES mecanico(id_mecanico)
) ENGINE=InnoDB;

CREATE TABLE servico (
  id_servico INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(80) NOT NULL,
  descricao VARCHAR(200),
  valor_mao_obra_ref DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE peca (
  id_peca INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(80) NOT NULL,
  descricao VARCHAR(200),
  valor_unit_ref DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE ordem_servico (
  id_os INT AUTO_INCREMENT PRIMARY KEY,
  num_os VARCHAR(20) NOT NULL UNIQUE,
  id_veiculo INT NOT NULL,
  id_equipe INT NOT NULL,
  data_emissao DATE NOT NULL,
  data_prevista DATE NOT NULL,
  data_conclusao DATE NULL,
  status ENUM('ABERTA','EM_EXECUCAO','AGUARDANDO_AUTORIZACAO','CONCLUIDA','ARQUIVADA','CANCELADA')
         NOT NULL DEFAULT 'ABERTA',
  autorizado ENUM('PENDENTE','AUTORIZADA','NEGADA') NOT NULL DEFAULT 'PENDENTE',
  data_autorizacao DATETIME NULL,
  valor_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT fk_os_veiculo FOREIGN KEY (id_veiculo) REFERENCES veiculo(id_veiculo),
  CONSTRAINT fk_os_equipe  FOREIGN KEY (id_equipe)  REFERENCES equipe(id_equipe)
) ENGINE=InnoDB;

CREATE TABLE os_servico (
  id_os INT NOT NULL,
  id_servico INT NOT NULL,
  qtd_horas DECIMAL(8,2) NOT NULL,
  valor_unit_mao_obra DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (id_os, id_servico),
  CONSTRAINT fk_oss_os      FOREIGN KEY (id_os)      REFERENCES ordem_servico(id_os) ON DELETE CASCADE,
  CONSTRAINT fk_oss_servico FOREIGN KEY (id_servico) REFERENCES servico(id_servico)
) ENGINE=InnoDB;

CREATE TABLE os_peca (
  id_os INT NOT NULL,
  id_peca INT NOT NULL,
  quantidade INT NOT NULL,
  valor_unit_peca DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (id_os, id_peca),
  CONSTRAINT fk_osp_os   FOREIGN KEY (id_os)   REFERENCES ordem_servico(id_os) ON DELETE CASCADE,
  CONSTRAINT fk_osp_peca FOREIGN KEY (id_peca) REFERENCES peca(id_peca)
) ENGINE=InnoDB;

CREATE TABLE forma_pagamento (
  id_forma INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(40) NOT NULL,
  UNIQUE (nome)
) ENGINE=InnoDB;

CREATE TABLE cliente_forma_pagamento (
  id_cliente INT NOT NULL,
  id_forma INT NOT NULL,
  detalhes VARCHAR(120),
  PRIMARY KEY (id_cliente, id_forma),
  CONSTRAINT fk_cfp_cliente FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
  CONSTRAINT fk_cfp_forma   FOREIGN KEY (id_forma)   REFERENCES forma_pagamento(id_forma)
) ENGINE=InnoDB;

CREATE TABLE pagamento (
  id_pagamento INT AUTO_INCREMENT PRIMARY KEY,
  id_os INT NOT NULL,
  id_forma INT NOT NULL,
  valor_pago DECIMAL(12,2) NOT NULL,
  data_pagamento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pg_os    FOREIGN KEY (id_os)   REFERENCES ordem_servico(id_os) ON DELETE CASCADE,
  CONSTRAINT fk_pg_forma FOREIGN KEY (id_forma) REFERENCES forma_pagamento(id_forma)
) ENGINE=InnoDB;

CREATE TABLE entrega (
  id_entrega INT AUTO_INCREMENT PRIMARY KEY,
  id_os INT NOT NULL UNIQUE,
  tipo ENUM('RETIRADA_NO_LOCAL','ENTREGA_DOMICILIAR') NOT NULL DEFAULT 'RETIRADA_NO_LOCAL',
  status ENUM('PENDENTE','EM_PREPARO','EM_ROTA','DISPONIVEL_RETIRADA','ENTREGUE','FALHA')
         NOT NULL DEFAULT 'PENDENTE',
  codigo_rastreio VARCHAR(50) NULL,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_entrega_os FOREIGN KEY (id_os) REFERENCES ordem_servico(id_os) ON DELETE CASCADE
) ENGINE=InnoDB;

-- View corrigida (sem erro de sintaxe)
DROP VIEW IF EXISTS vw_os_totais;

CREATE VIEW vw_os_totais AS
SELECT
  os.id_os,
  COALESCE(s.total_servicos, 0) + COALESCE(p.total_pecas, 0) AS total
FROM ordem_servico os
LEFT JOIN (
  SELECT id_os, SUM(subtotal) AS total_servicos
  FROM os_servico
  GROUP BY id_os
) s ON s.id_os = os.id_os
LEFT JOIN (
  SELECT id_os, SUM(subtotal) AS total_pecas
  FROM os_peca
  GROUP BY id_os
) p ON p.id_os = os.id_os;
