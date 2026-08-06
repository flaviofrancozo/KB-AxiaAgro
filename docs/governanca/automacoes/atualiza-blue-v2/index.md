# Governança — Atualiza BLUE V2

## Identificação

| Campo | Valor |
|---|---|
| Processo | Atualiza BLUE V2 — distribuição automatizada |
| Ambiente | Windows / volume `D:\PERFIL` |
| Destino | `D:\PERFIL\<hash>\Blue` |
| Tecnologia | PowerShell e Robocopy |
| Script | `Atualiza_BLUE_V2.ps1` |
| Execução | Manual ou agendada |
| Identidade agendada | `SYSTEM` |
| Responsável técnico | Equipe de Infraestrutura de TI |
| Classificação | Uso interno |

## Finalidade

Padronizar a atualização de arquivos em múltiplas pastas de usuários, reduzindo execução manual, inconsistência de versão e ausência de evidências.

## Escopo

Inclui:

- inventário automático das pastas-hash em `D:\PERFIL`;
- geração de `hash.txt`;
- cópia recursiva para a subpasta `Blue`;
- substituição quando a origem for mais nova;
- repetição dos destinos com falha;
- execução imediata ou agendada;
- geração de logs e relatório CSV.

Não inclui:

- exclusão de arquivos extras;
- encerramento forçado de processos;
- backup automático da versão anterior;
- distribuição para caminhos fora de `D:\PERFIL`;
- acesso automático a compartilhamentos que não concedam permissão ao `SYSTEM`.

## Justificativa

A distribuição manual para centenas de destinos gera risco de omissão, divergência de versão e falta de rastreabilidade. A automação aplica uma regra uniforme e mantém evidências por hash e ciclo.

## Papéis e responsabilidades

| Papel | Responsabilidade |
|---|---|
| Solicitante | Informar pacote, versão, janela e justificativa |
| Infraestrutura | Validar origem, executar/agendar e acompanhar ciclos |
| Dono da aplicação | Aprovar versão e confirmar compatibilidade |
| Segurança/Governança | Revisar acesso, retenção e evidências quando aplicável |
| Auditoria | Consultar evidências preservadas, sem alterar originais |

## Controles implementados

- validação do padrão de hash;
- destino restrito à raiz `D:\PERFIL`;
- inventário atualizado a cada execução;
- ausência de `/MIR` e `/PURGE`;
- substituição condicionada à data da origem;
- repetição somente dos hashes pendentes;
- execução agendada com identidade conhecida;
- logs com data/hora, ciclo, destino, resultado e código;
- consolidação dos logs temporários;
- possibilidade de validação por SHA-256.

## Riscos e tratamentos

| Risco | Impacto | Tratamento |
|---|---|---|
| Distribuição de versão incorreta | Indisponibilidade da aplicação | Aprovação da versão, piloto e SHA-256 |
| Arquivo em uso | Atualização parcial | Ciclos de repetição e log de pendência |
| Permissão insuficiente | Falha de cópia | Execução elevada e validação do código Robocopy |
| Origem removida antes do agendamento | Tarefa falha | Preservar origem até a conclusão e validar `LastTaskResult` |
| Script movido após agendamento | Tarefa não inicia | Manter caminho operacional permanente |
| Execução como SYSTEM | Alteração com alto privilégio | Restringir escrita no script e revisar tarefas criadas |
| Ausência de backup | Rollback indisponível | Manter pacote anterior aprovado antes da mudança |
| Exposição de logs no GitHub público | Divulgação de informações internas | Publicar somente evidências sanitizadas |

## Segregação e aprovação

Antes da execução em produção, registrar:

- número da mudança ou chamado;
- solicitante e aprovador;
- versão anterior e nova;
- hash SHA-256 do pacote de origem;
- quantidade prevista de pastas;
- janela de execução;
- plano de validação;
- pacote de rollback.

## Evidências mínimas

- chamado ou mudança aprovada;
- hash SHA-256 dos arquivos distribuídos;
- `hash.txt` utilizado;
- log principal;
- relatório CSV;
- registro da tarefa, quando agendada;
- resultado `LastTaskResult`;
- validação de pelo menos um destino piloto;
- evidência de rollback, caso utilizado.

## Retenção

Os logs originais devem ser mantidos em armazenamento restrito e protegido contra alteração, pelo período definido na política corporativa de retenção. Na ausência de prazo formal, recomenda-se que Governança aprove um prazo mínimo coerente com o ciclo de auditoria.

O site público deve conter somente exemplos sanitizados. A autenticação do site não torna privado um repositório GitHub público.

## Integridade das evidências

Gere um manifesto antes de arquivar:

```powershell
$Pasta = "D:\PERFIL\TEMP\Logs"

Get-ChildItem -LiteralPath $Pasta -File |
    Get-FileHash -Algorithm SHA256 |
    Select-Object Path, Algorithm, Hash |
    Export-Csv `
        -LiteralPath "$Pasta\Manifesto_SHA256.csv" `
        -Delimiter ";" `
        -NoTypeInformation `
        -Encoding UTF8
```

O manifesto deve ser preservado junto aos arquivos originais.

## Relação com boas práticas

| Referência | Aplicação |
|---|---|
| ISO/IEC 27001:2022 A.8.9 | Gestão de configuração e versão distribuída |
| ISO/IEC 27001:2022 A.8.13 | Backup necessário para rollback |
| ISO/IEC 27001:2022 A.8.15 | Registro e preservação de logs |
| ISO/IEC 27001:2022 A.8.18 | Controle de ferramentas administrativas privilegiadas |
| LGPD — segurança e prevenção | Minimização e proteção de evidências com identificadores internos |

## Checklist de mudança

### Antes

- [ ] Origem aprovada e preservada
- [ ] SHA-256 registrado
- [ ] Backup/rollback disponível
- [ ] Janela aprovada
- [ ] Caminho do script permanente
- [ ] Espaço livre verificado
- [ ] Piloto definido

### Durante

- [ ] Ciclo acompanhado
- [ ] Códigos `8+` investigados
- [ ] Nenhuma exclusão inesperada observada
- [ ] Tarefa agendada validada, quando aplicável

### Depois

- [ ] Todos os hashes concluídos
- [ ] CSV revisado
- [ ] Log principal preservado
- [ ] SHA-256 das evidências gerado
- [ ] Aplicação validada
- [ ] Mudança encerrada
- [ ] Somente evidência sanitizada publicada

## Histórico

| Data | Versão | Alteração | Responsável |
|---|---:|---|---|
| 06/08/2026 | 1.0 | Documentação inicial da automação reutilizável, ciclos, logs e agendamento | Infraestrutura de TI |

