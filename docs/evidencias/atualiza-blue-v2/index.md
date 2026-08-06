# Evidências — Atualiza BLUE V2

## Objetivo

Definir quais evidências devem ser preservadas após cada distribuição e quais podem ser publicadas no TechDocs.

## Evidência original restrita

Origem operacional:

```text
D:\PERFIL\TEMP\Logs
```

Preservar em repositório restrito:

- `Atualiza_BLUE_V2_Principal_*.log`;
- `Atualiza_BLUE_V2_Resultado_*.csv`;
- `hash.txt` da execução;
- manifesto SHA-256;
- captura/exportação da tarefa agendada;
- chamado ou mudança autorizadora;
- validação da aplicação.

Os arquivos originais podem conter hashes de pastas, caminhos internos, horários e mensagens de erro. Não devem ser enviados sem tratamento para repositório público.

## Evidência publicável

Nesta página podem ser disponibilizados:

- exemplos com hashes fictícios;
- resumo agregado de resultados;
- contagem total de sucessos e falhas;
- código da mudança, se autorizado;
- manifesto dos arquivos sanitizados;
- procedimento utilizado.

Exemplos incluídos:

- [Log principal sanitizado](logs-publicaveis/EXEMPLO_Atualiza_BLUE_V2_Principal.log)
- [Relatório CSV sanitizado](logs-publicaveis/EXEMPLO_Atualiza_BLUE_V2_Resultado.csv)

## Sanitização obrigatória

Antes da publicação:

1. Faça uma cópia do log; nunca altere o original.
2. Substitua hashes reais por identificadores fictícios.
3. Remova nomes de usuários, credenciais, tokens e compartilhamentos internos.
4. Remova caminhos que revelem arquitetura sensível, mantendo apenas o padrão documentado.
5. Revise mensagens do Robocopy.
6. Gere SHA-256 da versão sanitizada.
7. Registre quem revisou e aprovou a publicação.

## Modelo de resumo para auditoria

| Campo | Preenchimento |
|---|---|
| Mudança/chamado | `CHG-XXXX` |
| Data da execução | `dd/MM/yyyy HH:mm` |
| Tipo | Imediata / Agendada |
| Origem/versionamento | Pacote aprovado e SHA-256 |
| Hashes inventariados | Quantidade |
| Ciclos executados | Quantidade |
| Sucessos finais | Quantidade |
| Pendências finais | Quantidade |
| Código final da tarefa | Quando aplicável |
| Validador | Nome/função |
| Local dos originais | Repositório restrito |

## Exportar informação da tarefa

```powershell
$Nome = "NOME EXATO DA TAREFA"

Get-ScheduledTask -TaskName $Nome |
    Export-ScheduledTask |
    Out-File `
        -LiteralPath "D:\PERFIL\TEMP\Logs\Tarefa_Agendada.xml" `
        -Encoding UTF8

Get-ScheduledTaskInfo -TaskName $Nome |
    Format-List * |
    Out-File `
        -LiteralPath "D:\PERFIL\TEMP\Logs\Resultado_Tarefa.txt" `
        -Encoding UTF8
```

## Controle de publicação

- [ ] Arquivo é uma cópia, não o original
- [ ] Hashes reais removidos
- [ ] Usuários e caminhos sensíveis removidos
- [ ] Credenciais/tokens ausentes
- [ ] Conteúdo revisado por segundo responsável
- [ ] Manifesto SHA-256 criado
- [ ] Publicação aprovada

