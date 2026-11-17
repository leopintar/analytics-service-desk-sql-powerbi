-- ==============================================================================
-- PROJETO: ANALYTICS DE SERVICE DESK E INFRAESTRUTURA DE TI (MODELO GLPI)
-- Autor: Leonardo de Freitas Pintar
-- Descrição: Criação de estrutura relacional, carga de dados operacionais e
--            consultas SQL para indicadores de SLA, MTTR e gargalos de TI.
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS ti_service_desk;
USE ti_service_desk;

-- 1. TABELA DE ANALISTAS / TÉCNICOS
CREATE TABLE tecnicos (
    id_tecnico INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    especialidade VARCHAR(50) NOT NULL,
    nivel VARCHAR(20) NOT NULL
);

-- 2. TABELA DE CATEGORIAS DE ATENDIMENTO
CREATE TABLE categorias_ti (
    id_categoria INT PRIMARY KEY AUTO_INCREMENT,
    nome_categoria VARCHAR(80) NOT NULL,
    sla_limite_horas INT NOT NULL
);

-- 3. TABELA DE CHAMADOS (TICKETS)
CREATE TABLE chamados_glpi (
    id_chamado INT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(150) NOT NULL,
    setor_solicitante VARCHAR(60) NOT NULL,
    prioridade ENUM('Baixa', 'Média', 'Alta', 'Crítica') NOT NULL,
    status ENUM('Aberto', 'Em Atendimento', 'Resolvido', 'Fechado') NOT NULL,
    data_abertura DATETIME NOT NULL,
    data_fechamento DATETIME NULL,
    id_categoria INT NOT NULL,
    id_tecnico INT NOT NULL,
    FOREIGN KEY (id_categoria) REFERENCES categorias_ti(id_categoria),
    FOREIGN KEY (id_tecnico) REFERENCES tecnicos(id_tecnico)
);

-- 4. POPULANDO DADOS REALISTAS DA OPERAÇÃO
INSERT INTO tecnicos (nome, especialidade, nivel) VALUES
('Leonardo Pintar', 'Infraestrutura e Redes', 'Pleno'),
('Carlos Mendes', 'Suporte N1 / Hardware', 'Júnior'),
('Mariana Souza', 'Sistemas ERP / Protheus', 'Pleno');

INSERT INTO categorias_ti (nome_categoria, sla_limite_horas) VALUES
('Redes e Conectividade (Switch/Wi-Fi)', 4),
('Servidores Windows/Linux e Backup', 4),
('ERP TOTVS Protheus (Acesso/Rotinas)', 8),
('Hardware, Estações e Impressoras', 12),
('Gestão de Acessos e Active Directory', 6);

INSERT INTO chamados_glpi (titulo, setor_solicitante, prioridade, status, data_abertura, data_fechamento, id_categoria, id_tecnico) VALUES
('Queda de link no Switch do Galpão B', 'Produção', 'Crítica', 'Fechado', '2026-11-02 08:10:00', '2026-11-02 09:45:00', 1, 1),
('Lentidão no acesso ao módulo Financeiro Protheus', 'Financeiro', 'Alta', 'Fechado', '2026-11-02 09:00:00', '2026-11-02 14:30:00', 3, 3),
('Substituição de SSD e imagem Windows 11', 'Compras', 'Média', 'Fechado', '2026-11-03 10:00:00', '2026-11-03 16:20:00', 4, 2),
('Criação de usuário AD e permissões de pasta', 'RH', 'Média', 'Fechado', '2026-11-04 08:30:00', '2026-11-04 10:00:00', 5, 1),
('Falha na rotina de backup noturno Linux', 'TI / Datacenter', 'Crítica', 'Fechado', '2026-11-05 07:15:00', '2026-11-05 10:50:00', 2, 1),
('Impressora térmica zebra sem comunicação IP', 'Expedição', 'Alta', 'Fechado', '2026-11-06 13:00:00', '2026-11-06 18:10:00', 4, 2),
('Erro de conexão DBACCESS no Protheus 12', 'Faturamento', 'Crítica', 'Fechado', '2026-11-07 08:00:00', '2026-11-07 17:30:00', 3, 3),
('Configuração de nova VLAN para câmeras CFTV', 'Segurança Patrimonial', 'Alta', 'Fechado', '2026-11-08 09:00:00', '2026-11-08 12:15:00', 1, 1);

-- ==============================================================================
-- CONSULTAS ANALÍTICAS (KPIs PARA DASHBOARD POWER BI)
-- ==============================================================================

-- KPI 1: Tempo Médio de Atendimento (MTTR em horas) e Taxa de Cumprimento de SLA por Categoria
SELECT 
    c.nome_categoria AS Categoria,
    COUNT(ch.id_chamado) AS Total_Chamados,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, ch.data_abertura, ch.data_fechamento) / 60), 2) AS MTTR_Horas,
    c.sla_limite_horas AS SLA_Meta_Horas,
    SUM(CASE 
        WHEN (TIMESTAMPDIFF(MINUTE, ch.data_abertura, ch.data_fechamento) / 60) <= c.sla_limite_horas THEN 1 
        ELSE 0 
    END) AS Dentro_do_SLA,
    ROUND(
        (SUM(CASE WHEN (TIMESTAMPDIFF(MINUTE, ch.data_abertura, ch.data_fechamento) / 60) <= c.sla_limite_horas THEN 1 ELSE 0 END) / COUNT(ch.id_chamado)) * 100, 
    1) AS Percentual_SLA
FROM chamados_glpi ch
INNER JOIN categorias_ti c ON ch.id_categoria = c.id_categoria
WHERE ch.status IN ('Resolvido', 'Fechado')
GROUP BY c.nome_categoria, c.sla_limite_horas
ORDER BY Percentual_SLA ASC;

-- KPI 2: Produtividade e Volume de Chamados Críticos/Altos por Analista
SELECT 
    t.nome AS Analista,
    t.especialidade AS Area,
    COUNT(ch.id_chamado) AS Chamados_Resolvidos,
    SUM(CASE WHEN ch.prioridade IN ('Alta', 'Crítica') THEN 1 ELSE 0 END) AS Incidentes_Alta_Criticidade,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, ch.data_abertura, ch.data_fechamento) / 60), 2) AS Tempo_Medio_Horas
FROM chamados_glpi ch
INNER JOIN tecnicos t ON ch.id_tecnico = t.id_tecnico
GROUP BY t.nome, t.especialidade
ORDER BY Chamados_Resolvidos DESC;

-- KPI 3: Ranking de Setores que Mais Demandam Suporte de TI
SELECT 
    setor_solicitante AS Setor,
    COUNT(*) AS Total_Tickets,
    SUM(CASE WHEN prioridade = 'Crítica' THEN 1 ELSE 0 END) AS Tickets_Criticos
FROM chamados_glpi
GROUP BY setor_solicitante
ORDER BY Total_Tickets DESC;
