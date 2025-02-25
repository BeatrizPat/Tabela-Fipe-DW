-- Dimensão Categoria
CREATE TABLE dimensao_categoria (
    ID_categoria SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL
);

-- Dimensão Tempo
CREATE TABLE dimensao_tempo (
    ID_tempo SERIAL PRIMARY KEY,
    ano INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    semestre INTEGER NOT NULL
);

-- Dimensão Versão
		CREATE TABLE dimensao_versao (
		    ID_versao INT PRIMARY KEY,
		    ano_modelo VARCHAR(50),
		    combustivel VARCHAR(50)
		);

-- Dimensão Modelo
		CREATE TABLE dimensao_modelo (
	    ID_modelo INT PRIMARY KEY,
	    marca VARCHAR(255),
	    modelo VARCHAR(255),
	    codigo_fipe VARCHAR(50),
	    ID_versao INT,  -- FK para a Dimensão Versão
	    FOREIGN KEY (ID_versao) REFERENCES dimensao_versao(ID_versao)
	);

-- Fato Preço
CREATE TABLE fato_preco (
    ID_fato SERIAL PRIMARY KEY,
    ID_categoria INTEGER NOT NULL,
    ID_modelo INTEGER NOT NULL,
    ID_tempo INTEGER NOT NULL,
    Preco DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (ID_categoria) REFERENCES dimensao_categoria(ID_categoria),
    FOREIGN KEY (ID_modelo) REFERENCES dimensao_modelo(ID_modelo),
    FOREIGN KEY (ID_tempo) REFERENCES dimensao_tempo(ID_tempo)
);
