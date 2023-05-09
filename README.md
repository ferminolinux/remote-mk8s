# remote-mk8s
Cluster do MK8S rodando na AWS


### Execução
Para implementar esse clsuter você pode executar os comandos do
terraform e do ansible separadamente.
```
$ terraform plan --out=plan.out && terraform apply plan.out
$ ansible-playbook -i inventory.yaml playbook.yaml
```

Também é possível executar os comandos todos juntos, utilizando o operador '&&', porém se tentar executar dessa forma se a instância demorar muito para inicializar talvez o ansible não consiga estabelecer a conexão SSH com ela, a vantagem de executar da primeira forma é que você pode simplesmente esperar a instância iniciar de fato. 
```
$ terraform plan --out=plan.out && \
    terraform apply plan.out && \
    ansible-playbook -i inventory.yaml playbook.yaml
```