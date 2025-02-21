Para executar o projeto:
    1. Navegue para a pasta src/ usando o comando "cd". Isso é essencial para o assembler buscar os arquivos corretos.
    2. Use o assembler nasm (testado 2.16.03) no arquibo InitGame.asm:
        nasm -f elf64 InitGame.asm -o ../InitGame.o
    3. Use um linker para produzir o executável:
        ld ../InitGame.o -o ../RPGPT
    4. Execute o programa!
        ../RPGPT

ATENÇÃO:
     - Para assemblar o programa, coloque um arquivo chamado .openai-api-key (sem extensão) contendo uma chave de api da OpenAI
    no diretório principal do projeto. Deixamos aqui um arquivo com alguns créditos, suficiente para teste. Esse arquivo será
    incluído pelo assembler no executável binário.

    - Os prompts na pasta prompts/ também devem estar acessíveis durante a assemblagem.

    - O programa precisa do Python 3 instalado no computador para funcionar corretamente durante a execução, bem como uma conexão à internet.
