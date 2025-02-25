--EXTENSÃO DBLINK
create extension dblink

-- Cria a conexão com o banco
SELECT dblink_connect('conexao_remota', 'host=localhost dbname=fipe user=postgres password=postgres');

--POPULANDO TABELAS DIMENSÃO
	--CATEGORIA
		INSERT INTO dimensao_categoria (nome) VALUES
		    ('Carro'),
		    ('Moto'),
		    ('Caminhão')
		ON CONFLICT DO NOTHING;

	--TEMPO
		INSERT INTO dimensao_tempo (ano, mes, trimestre, semestre)
			SELECT DISTINCT 
		    EXTRACT(YEAR FROM TO_DATE(datareferencia, 'YYYY-MM-DD')) AS ano,
		    EXTRACT(MONTH FROM TO_DATE(datareferencia, 'YYYY-MM-DD')) AS mes,
		    CASE 
		        WHEN EXTRACT(MONTH FROM TO_DATE(datareferencia, 'YYYY-MM-DD')) IN (1,2,3) THEN 1
		        WHEN EXTRACT(MONTH FROM TO_DATE(datareferencia, 'YYYY-MM-DD')) IN (4,5,6) THEN 2
		        WHEN EXTRACT(MONTH FROM TO_DATE(datareferencia, 'YYYY-MM-DD')) IN (7,8,9) THEN 3
		        ELSE 4 
		    END AS trimestre,
		    CASE 
		        WHEN EXTRACT(MONTH FROM TO_DATE(datareferencia, 'YYYY-MM-DD')) <= 6 THEN 1 
		        ELSE 2 
		    END AS semestre
		FROM dblink('conexao_remota', 'SELECT DISTINCT datareferencia FROM dados_fipe')
		AS fonte(datareferencia VARCHAR)
		ON CONFLICT DO NOTHING;

	--VERSÃO
		INSERT INTO dimensao_versao (ano_modelo, combustivel)
		SELECT DISTINCT ano, combustivel
		FROM dblink('conexao_remota', 'SELECT DISTINCT ano, combustivel FROM dados_fipe')
		AS fonte(ano INTEGER, combustivel VARCHAR)
		ON CONFLICT DO NOTHING;

	--MODELO
		INSERT INTO dimensao_modelo (marca, modelo, codigo_fipe, id_versao)
		SELECT DISTINCT marca, modelo, codigofipe, v.id_versao
		FROM dblink('conexao_remota', 'SELECT DISTINCT marca, modelo, ano, codigofipe, combustivel FROM dados_fipe')
		AS fonte(marca VARCHAR, modelo VARCHAR, ano VARCHAR, codigofipe VARCHAR, combustivel VARCHAR)
		JOIN dimensao_versao v ON fonte.ano = v.ano_modelo and fonte.combustivel = v.combustivel
		ON CONFLICT DO NOTHING;

--POPULANDO TABELA FATO
	-- Inserindo os dados na tabela Fato_Preco
		INSERT INTO fato_preco (ID_categoria, ID_modelo, ID_tempo, preco)
		SELECT 
		    c.ID_categoria,
		    m.ID_modelo,
		    t.ID_tempo,
		    fonte.preco
		FROM dblink('conexao_remota', 'SELECT DISTINCT tipo, marca, modelo, codigofipe, datareferencia, preco FROM dados_fipe')
		AS fonte(categoria VARCHAR, marca VARCHAR, modelo VARCHAR, codigofipe VARCHAR, datareferencia VARCHAR, preco DECIMAL)
		JOIN (
		    SELECT DISTINCT ON (marca, modelo, codigo_fipe) * FROM dimensao_modelo
		) m ON fonte.marca = m.marca AND fonte.modelo = m.modelo AND fonte.codigofipe = m.codigo_fipe
		JOIN (
		    SELECT DISTINCT ON (ano, mes) * FROM dimensao_tempo
		) t ON EXTRACT(YEAR FROM TO_DATE(fonte.datareferencia, 'YYYY-MM-DD')) = t.ano
		   AND EXTRACT(MONTH FROM TO_DATE(fonte.datareferencia, 'YYYY-MM-DD')) = t.mes
		JOIN dimensao_categoria c ON fonte.categoria = c.nome
		ON CONFLICT DO NOTHING;

-- MOSTRAR A TABELA FATO
select * from fato_preco

--verificar registros duplicados na fato
SELECT ID_categoria, ID_modelo, ID_tempo, preco, COUNT(*)
FROM fato_preco
GROUP BY ID_categoria, ID_modelo, ID_tempo, preco
HAVING COUNT(*) > 1;

-- Fechar a conexão com o banco de dados remoto
SELECT dblink_disconnect('conexao_remota');