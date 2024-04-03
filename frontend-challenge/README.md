# Segdev - Desafio Frontend

## O desafio
Você foi contratado para desenvolver um formulário básico utilizando **Vue.js** ou **Nuxt** para uma aplicação web no mercado de seguros. O formulário deve permitir que os usuários insiram informações relacionadas ao processo. Além disso, é necessário realizar a validação dos campos para garantir que os dados inseridos sejam válidos. 

#### Requisitos
Você deve desenvolver o formulário em uma única página, porém, esse formulário possui campos variáveis de acordo com o tipo de solicitação selecionado pelo usuário (judicial/contratual).

* Para popular o campo "Tipo da solicitação", você deve realizar um GET para o seguinte endpoint: 1.  https://teste-worker.wapesolucoes.workers.dev/api/solicitation
* 
1.  **Campos do formulário (Contratual):**
    -   **Tipo de solicitação**: Obrigatório, deve ser "judicial" e precisa ser selecionado antes de gerar os campos do formulário.
    -   **Tomador**: Deve ser um objeto contendo os campos abaixo:
	    -   **Nome completo**: Deve possuir no mínimo 2 caracteres e sobrenome.
	    -   **Documento**: Deve ser um CNPJ válido.
	    - **CEP**: Deve ser um CEP válido (deve ser utilizada a API [ViaCEP](https://viacep.com.br))
	    - **Rua**: Deve possuir no mínimo 2 caracteres (preencher de acordo com a API, porém, caso o valor não exista na API, deixar o usuário preencher).
	    - **Bairro**: Deve possuir no mínimo 2 caracteres (preencher de acordo com a API, porém, caso o valor não exista na API, deixar o usuário preencher).
	  - **Processo**: um objeto contendo os campos abaixo:
		  - **Valor do processo** (R$): Deve ser maior que 0,01.
		  - **Observações**: Campo de texto não obrigatório.
		  
1.  **Campos do formulário (Contratual):**
    -   **Tipo de solicitação**: Obrigatório, deve ser "*contractual*" e precisa ser selecionado antes de gerar os campos do formulário.
    -   **Segurado**: Deve ser um objeto contendo os campos abaixo:
	    -   **Nome completo**: Deve possuir no mínimo 2 caracteres e sobrenome.
	    -   **Documento**: Deve ser um CNPJ válido.
	    - **CEP**: Deve ser um CEP válido (deve ser utilizada a API [ViaCEP](https://viacep.com.br))
	    - **Rua**: Deve possuir no mínimo 2 caracteres (preencher de acordo com a API, porém, caso o valor não exista na API, deixar o usuário preencher).
	    - **Bairro**: Deve possuir no mínimo 2 caracteres (preencher de acordo com a API, porém, caso o valor não exista na API, deixar o usuário preencher).
	  - **Contrato**: um objeto contendo os campos abaixo:
		  - **Valor do contrato** (R$): Deve ser maior que 0,01.
		  - **Observações**: Campo de texto não obrigatório.
2.  **Validação:**
    
    -   Todos os campos são obrigatórios,  exceto **observações**.
    -   Os campos devem ser validados em tempo real, ou seja, conforme o usuário digita.
    -   Deve ser exibida uma mensagem de erro específica para cada campo caso os dados inseridos não estejam de acordo com os requisitos.
    
4.  **Tecnologias:**
    
    -   Você pode utilizar bibliotecas que auxiliam na validação e criação do formulário, como: Formkit, VeeValidate, Zod, Vuelidate.
    -   Você pode utilizar bibliotecas adicionais caso necessite.
   
3.  **Exibição de Dados:**
    
    -   Após o envio do formulário, você deve loggar um objeto conforme esperado abaixo, note que são dois objetos diferentes, de acordo com **Tipo da Solicitação**.

## Objeto esperado -> Judicial
    { 
	    "solicitation_type":  "judicial", 
	    "policy_holder":  {
			"name":  "Fulano de Tal",
			"document":  "CNPJ",
			"cep":  "00000-000",
			"street":  "Rua X",
			"neighborhood":  "Bairro Y"
		},
		"process":  {
			"insured_amount":  10000,
			"observations":  "Texto grande para descrição da solicitação"
		}
	}

## Objeto esperado -> Contratual
    { 
	    "solicitation_type":  "contractual", 
	    "insured":  {
			"name":  "Fulano de Tal",
			"document":  "CPF",
			"cep":  "00000-000",
			"street":  "Rua X",
			"neighborhood":  "Bairro Y"
		},
		"contract":  {
			"insured_amount":  10000,
			"observations":  "Texto grande para descrição da solicitação"
		}
	}
