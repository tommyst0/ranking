# Ranking
Este projeto implementa um sistema de ranking simples e eficiente, desenvolvido em Pawn, que mantém uma lista ordenada de jogadores com base em seus pontos. Ele usa cache local para acesso rápido e MySQL para persistência durável dos dados.
O sistema suporta notificações em tempo real para jogadores online e é configurável para diferentes tamanhos de ranking.

# Funções
```c
rank_create(const rank_name[])
// cria um rank
                                
rank_reset(const rank_name[])
// reseta o rank
                       
rank_delete(const rank_name[])
// deleta um rank
             
rank_exists(const rank_name[])
// verifica se um rank existe

rank_check(const rank_name[], const name[], points)                 
// atualiza o rank
                                           
rank_get(const rank_name[], const value_name[])
// pega a lista do rank para dialog
          
rank_get_print(const rank_name[], const value_name[])
// pega a lista do rank para printar no console
                                                                    
set_rank_name_points(const rank_name[], id, const name[], points)
// seta nome e pontos no rank

exists_name_rank(const rank_name[], const rank_player[])
// verifica se um nome esta no rank
     
remove_name_rank(const rank_name[], const rank_player[])
// remove um nome do rank
```

# Funcionamento
- Não é **Bubble Sort**, é um sistema rapido, simples e sem complexidade, com proposíto de não irritar a CPU do servidor (que já é fraca)</br>
- Sem acumulo de cache (mysql).</br>
- Lógica de inserção no ranking clara e funcional.</br>
- Notifica o jogador se estiver online da nova posição.</br>
- Usa loop para deslocar os ranks existentes para manter a ordem.</br>
- Atualiza o banco de dados e cache de forma sincronizada.</br>
  - um cada vez, sem a necessidade do uso de um sistema que funcione em encadeias de forma simultanea</br>

### Fluxograma
```
Player 500   Player 400
   |            |
   |         looping (repetir comparação)
   |            |
   |       player I > player II?  -> se sim, manter ordem
   |       player I < player II?  -> se sim, trocar ordem
   |
Resultado:
1. player II
2. player I
```

# Bubble Sort
```c
//
// create_rank_var(array_);
//      array_ -> array que vai pecorrer
//

new ArenaKills[MAX_PLAYERS];
stock rank_arena(array_)
{
    new topPlayers[MAX_PLAYERS], topKills[MAX_PLAYERS], count = 0;

    for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++)
    {
        topPlayers[count] = i;
        topKills[count] = ArenaKills[i];
        count++;
    }

    for (new i = 0; i < count - 1; i++) {
        for (new j = 0; j < count - i - 1; j++) {
            if (topKills[j] < topKills[j + 1]) {
                new tempKills = topKills[j];
                new tempPlayer = topPlayers[j];
                
                topKills[j] = topKills[j + 1];
                topPlayers[j] = topPlayers[j + 1];
                
                topKills[j + 1] = tempKills;
                topPlayers[j + 1] = tempPlayer;
            }
        }
    }

    new msg[(21+24+20) * MAX_RANK], name[MAX_PLAYER_NAME];
    format(msg, sizeof(msg), "[RANK] Top %d jogadores:\n", MAX_RANK);
    
    for (new i = 0; i < count && i < MAX_RANK; i++) {
        if (IsPlayerConnected(topPlayers[i])) {
            GetPlayerName(topPlayers[i], name, sizeof(name));
        } else {
            format(name, sizeof(name), "(Offline)");
        }
        format(msg, sizeof(msg), "%s%d. %s - %d kills\n", msg, i + 1, name, topKills[i]);
    }
    print(msg);
    return 1;
}
```
