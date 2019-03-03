---
version: 1.1.0
title: Changesets
---

Para inserir, atualizar ou excluir as informações de um banco de dados, `Ecto.Repo.insert/2`, `update/2` e `delete/2` é necessário um changeset como primeiro parâmetro.
Mas o que são exatamente changesets?

Uma tarefa comum para quase todos os desenvolvedores é verificar os dados de entrada para possíveis erros — Queremos ter certeza de que os dados estão no estado correto antes de tentarmos usá-los para nossos propósitos.

O Ecto fornece uma solução completa para trabalhar com alteração de dados na forma do módulo `Changeset` e de estruturas de dados. Nesta lição, vamos explorar essa funcionalidade e aprender a verificar a integridade dos dados antes de persisti-los no banco de dados.
