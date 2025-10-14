# Segdev - Backend Desafio 3 - API de Apólices e Endossos

## Contexto

Você deve implementar uma **API em Ruby on Rails (API-only)** para gerenciar **apólices de seguro** e seus **endossos**.  
O sistema deve permitir criar e consultar apólices e endossos, seguindo as regras de negócio descritas abaixo.

---

## Definições

### Apólice

A **apólice** representa o contrato de seguro firmado entre o segurado e a seguradora.

**Campos obrigatórios:**
- `numero` — identificador único da apólice  
- `data_emissao` — data em que a apólice foi emitida  
- `inicio_vigencia` — data de início da cobertura  
- `fim_vigencia` — data de término da cobertura  
- `importancia_segurada` — valor de referência original  
- `lmg` — limite máximo de garantia (valor máximo atual de cobertura, após todos os endossos)  

A apólice deve sempre refletir os **dados vigentes**, considerando os endossos aplicados.

---

### Endosso

O **endosso** é uma alteração registrada em uma apólice existente.

**Campos esperados:**
- Data de emissão  
- Tipo de endosso  
- Valores e datas 
- Relações de cancelamento, quando aplicável

Endossos são **imutáveis**: não podem ser editados nem apagados.

---

## Tipos de Endosso

Os tipos de endosso devem ser determinados automaticamente a partir das diferenças entre os dados informados e os dados vigentes da apólice.

| Tipo | Descrição |
|------|------------|
| `aumento_is` | Aumenta a importância segurada (IS) |
| `reducao_is` | Reduz a importância segurada (IS) |
| `alteracao_vigencia` | Altera o período de vigência |
| `aumento_is_alteracao_vigencia` | Aumenta a IS e altera a vigência |
| `reducao_is_alteracao_vigencia` | Reduz a IS e altera a vigência |
| `cancelamento` | Cancela o último endosso válido |

---

## Regras de Negócio

1. A **importância segurada (IS)** é o valor usado para atualizar o **LMG** da apólice.  
   Após cada endosso válido, o LMG deve refletir o valor vigente da IS.

2. O **tipo de endosso** deve ser determinado automaticamente com base nas diferenças entre os dados informados e os dados atuais da apólice.

3. Um **endosso de cancelamento** deve:
   - Cancelar o **último endosso válido** (não cancelado e que não seja de cancelamento).  
   - Criar a relação de referência entre o endosso cancelado e o de cancelamento:  
   - Caso o cancelamento torne a apólice inválida, a apólice deve ser marcada como **BAIXADA**.

4. Ao **consultar uma apólice**, a API deve retornar:
   - Todos os dados vigentes  
   - O **LMG** atual após aplicação dos endossos válidos  
   - O **status** atual (`ATIVA` ou `BAIXADA`)

5. **Apólices e endossos não podem ser apagados nem alterados.**  
   Apenas criação (`POST`) e consulta (`GET`) são permitidas.

---

## Funcionalidades Obrigatórias

### Apólices
- Criar apólice  
- Consultar apólice com seus endossos
- Listar apólices  

### Endossos
- Criar endosso sobre uma apólice  
- Consultar endosso  
- Listar endossos de uma apólice  

---

## Regras Gerais

- Todos os campos obrigatórios devem ser validados.  
- Validar campos:
 - LMG não pode ficar negativo
 - O fim da vigência não pode ser anterior ao inicio
 - O inicio da vigência pode ser no passado ou no futuro da data de emissão em no maximo 30 dias.
 - Outras validações que achar relevantes
- Não deve ser possível criar endossos inconsistentes (ex: vigência inválida).  
- O histórico de endossos deve ser preservado integralmente.  
- A aplicação deve garantir a integridade das referências entre endossos cancelados e canceladores.

---

## Testes Automatizados

Deve ser entregue uma suíte de testes cobrindo os principais fluxos funcionais:
- Criação de apólice  
- Criação de endossos de todos os tipos  
- Cancelamento do endosso atual
- Atualização do LMG e status da apólice 

---

## Postman

Deve ser entregue uma **collection do Postman** contendo:
- Todas as requisições necessárias para criar e consultar apólices e endossos  
- Automação entre as requisições  

## Docker

Deve ter um dockerfile e docker_compose.yml para rodar a aplicação localmente

---

## Critérios de Avaliação

| Critério | Descrição |
|-----------|------------|
| **Modelagem de dados** | Correção e consistência das relações |
| **Regras de negócio** | Implementação conforme as definições |
| **Testes automatizados** | Cobertura dos fluxos principais |
| **Collection Postman** | Completude e funcionamento |
| **Clareza** | Estrutura, nomeação e documentação |

---

## Entrega

- O código deve ser entregue em um repositório público (GitHub ou GitLab).  
- Incluir instruções de execução no `README.md`.  
- Incluir a collection do Postman na raiz do projeto (`postman_collection.json`).  
- O desafio deve estar funcional e testável.

---
