# 📊 Analytics de Service Desk e Infraestrutura de TI (SQL + Power BI)

Projeto de análise de dados operacionais de TI inspirado na estrutura do sistema **GLPI**, utilizando **SQL (MySQL)** para modelagem relacional, cálculo de indicadores de desempenho (**SLA** e **MTTR**) e preparação de visão analítica para dashboards no **Power BI**.

---

## 🎯 Objetivo de Negócio
Equipes de Infraestrutura e Suporte precisam transformar registros brutos de chamados em indicadores claros para identificar gargalos, dimensionar capacidade técnica e prevenir indisponibilidades recorrentes em redes, servidores e sistemas ERP (**TOTVS Protheus**).

### Indicadores Extraídos via SQL:
* **MTTR (*Mean Time To Repair*):** Tempo médio em horas entre a abertura e a solução definitiva do incidente.
* **Taxa de Cumprimento de SLA (%):** Comparação automática entre o tempo real de resolução e o limite acordado por categoria de serviço.
* **Mapa de Calor por Setor e Criticidade:** Identificação das áreas da empresa com maior volume de chamados críticos.

---

## 🗂️ Estrutura do Banco de Dados
O script [`analise_sla_glpi.sql`](./analise_sla_glpi.sql) implementa três tabelas normalizadas:
1. `tecnicos`: Cadastro dos analistas, especialidades e senioridade.
2. `categorias_ti`: Classificação dos serviços de TI e suas respectivas metas de SLA em horas.
3. `chamados_glpi`: Registro completo dos tickets com timestamps de abertura/fechamento, prioridade e chaves estrangeiras.

---

## 📈 Medidas DAX Equivalentes para o Power BI
Para conectar esta base SQL ao **Power BI**, as seguintes métricas complementam a camada visual:

```dax
Total Chamados = COUNT(chamados_glpi[id_chamado])

MTTR (Horas) = 
AVERAGEX(
    chamados_glpi,
    DATEDIFF(chamados_glpi[data_abertura], chamados_glpi[data_fechamento], MINUTE) / 60
)

% SLA Atendido = 
DIVIDE(
    CALCULATE(COUNT(chamados_glpi[id_chamado]), chamados_glpi[Status_SLA] = "No Prazo"),
    [Total Chamados],
    0
)
```

---
**Desenvolvido por:** [Leonardo de Freitas Pintar](https://github.com/leopintar) — *Engenheiro de Computação | Infraestrutura, ERP & Dados*
