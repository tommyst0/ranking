/*

    __________________________________________________________________________
    |                                                                         |
    |                           Sistema de Ranking                            |
    |                                                                         |
    |   rank_create(const rank_name[])                                        |
    |   rank_reset(const rank_name[])                                         |
    |   rank_delete(const rank_name[])                                        |
    |   rank_exists(const rank_name[])                                        |
    |   rank_check(const rank_name[], const name[], points)                   |
    |                                                                         |
    |   rank_get(const rank_name[], const value_name[])                       |
    |   rank_get_print(const rank_name[], const value_name[])                 |
    |                                                                         |
    |   set_rank_name_points(const rank_name[], id, const name[], points)     |
    |   exists_name_rank(const rank_name[], const rank_player[])              |
    |   remove_name_rank(const rank_name[], const rank_player[])              |
    |                                                                         |
    ---------------------------------------------------------------------------
    |                        Criado por tommy_stardust                        |
    ---------------------------------------------------------------------------

    Exemplo de Uso:

        rank_create("dinheiro");

        if(rank_exists("dinheiro"))
        {
            rank_check("dinheiro", "pica", 9);
            rank_check("dinheiro", "ouic", 9);
            rank_check("dinheiro", "mijo", 9); // 10
            rank_check("dinheiro", "bosta", 9); // 9
            rank_check("dinheiro", "mateus", 10);// 8
            rank_check("dinheiro", "mesquita", 15); // 7
            rank_check("dinheiro", "cu", 52); // 6
            rank_check("dinheiro", "laiisaw", 1001); // 5
            rank_check("dinheiro", "lima", 2007); // 4
            rank_check("dinheiro", "moschee", 2025); // 3
            rank_check("dinheiro", "laisa", 20000); // 2
            rank_check("dinheiro", "20tecomer70correr", 90000); // 1


            print(rank_get_print("dinheiro", "dinheiros"));
        }

*/


#define MAX_RANK (10+1) // max de posicoes no rank (se mudar aqui, muda no create table, ok?)

#if !defined RANK_DEBUG
    #define RANK_DEBUG (DEBUG_LOAD_PRINT) // rank debug print (Ex: rank 'x' foi criado)
#endif

#if !defined IsPlayerOnlineEx
    stock IsPlayerOnlineEx(const name[])
    {
        new id = -1;
        static nme[MAX_PLAYER_NAME];
        foreach(new i: Player)
        {
            GetPlayerName(i, nme, sizeof(nme));
            if(strcmp(name,nme,true)==0)
            {
                id = i;
                break;
            }
        }
        return id;
    }
#endif

new name__[MAX_RANK][MAX_PLAYER_NAME], points__[MAX_RANK];

#include "../modulos/server/rank/rank_load.sys"
#include "../modulos/server/rank/rank_visual.sys"
#include "../modulos/server/rank/comandos.sys"

// pega a lista do rank para dialog
stock rank_get(const rank_name[], const value_name[])
{
	new query[130], rank__[768];
	mysql_format(Database, query, sizeof(query), "SELECT * FROM `ranks` WHERE `rank` = '%s'", rank_name);
	new Cache:result = mysql_query(Database, query);


	if(cache_is_valid(result))
	{
		if(cache_num_rows() > 0)
        {
            new String[128];

            //
            for(new i = 1; i < MAX_RANK; ++i)
            {
    			cache_get_value_name(0, fmat_return("rank_name%i", i), name__[i]);
    			cache_get_value_name_int(0, fmat_return("rank_point%i", i), points__[i]);

                format(String, sizeof String, "{ffffff}%i� {00aaff}%s\t\t{6e6e6e}(%s): {FFFFFF}%i\n", i, name__[i], value_name, points__[i]);
                strpack(String, String);
                strpackcat(rank__, String);
            }

			cache_unset_active();
			cache_delete(result);
		}
	}
    return rank__;
}

// pega a lista do rank para printar no console
stock rank_get_print(const rank_name[], const value_name[])
{
	new query[130], rank__[768];
	mysql_format(Database, query, sizeof(query), "SELECT * FROM `ranks` WHERE `rank` = '%s'", rank_name);
	new Cache:result = mysql_query(Database, query);


	if(cache_is_valid(result))
	{
		if(cache_num_rows() > 0)
        {
            new String[128];

            //
            for(new i = 1; i < MAX_RANK; ++i)
            {
    			cache_get_value_name(0, fmat_return("rank_name%i", i), name__[i]);
    			cache_get_value_name_int(0, fmat_return("rank_point%i", i), points__[i]);

                format(String, sizeof String, "%i %s (%s): %i\n", i, name__[i], value_name, points__[i]);
                strpack(String, String);
                strpackcat(rank__, String);
            }

			cache_unset_active();
			cache_delete(result);
		}
	}
    return rank__;
}

// cria um rank
stock rank_create(const rank_name[])
{
    if(!rank_exists(rank_name))
    {
        new query[130];
        format(query, 90, "INSERT INTO `ranks`(`rank`) VALUES ('%s')", rank_name);
        mysql_query(Database, query, false);

        rank_reset(rank_name);

        #if RANK_DEBUG == true
            printf("[rank]: %s criado com sucesso!", rank_name);
        #endif
    }
    return 1;
}

// reseta o rank
stock rank_reset(const rank_name[])
{
    if(rank_exists(rank_name))
    {
        new Result[760], String[64];
        strpack(String, "UPDATE `ranks` SET");
        strpackcat(Result, String);
        for(new i = 1; i < MAX_RANK; ++i)
        {
            format(String, sizeof(String), "`rank_name%i`='Ninguem',", i);
            strpack(String, String);
            strpackcat(Result, String);

            format(String, sizeof(String), "`rank_point%i`='0',", i);
            strpack(String, String);
            strpackcat(Result, String);
        }
        strpack(String, fmat_return("`antbug`='0' WHERE `rank`='%s'", rank_name));
        strpackcat(Result, String);
        mysql_query(Database, Result, false);

        #if RANK_DEBUG == true
            printf("[rank]: %s foi resetado com sucesso!", rank_name);
        #endif
        return 1;
    }
    return 0;
}

// deleta um rank
stock rank_delete(const rank_name[])
{
    if(rank_exists(rank_name))
    {
        mysql_query(Database, fmat_return("DELETE FROM `ranks` WHERE `rank`='%s'", rank_name), false);

        #if RANK_DEBUG == true
            printf("[rank]: %s foi deletado com sucesso!", rank_name);
        #endif
        return 1;
    }
    return 0;
}

// verifica se um rank existe
stock rank_exists(const rank_name[])
{
	new query[130], existe = 0;
	mysql_format(Database, query, sizeof(query), "SELECT * FROM `ranks` WHERE `rank` = '%s'", rank_name);
	new Cache:result = mysql_query(Database, query);

	if(cache_is_valid(result))
	{
		if(cache_num_rows() > 0){
            existe = 1;
			cache_unset_active();
			cache_delete(result);
		}
	}
	return existe;
}

// seta nome e pontos no rank
stock set_rank_name_points(const rank_name[], id, const name[], points)
{
    new String[80+50];
    format(String, sizeof(String), "UPDATE `ranks` SET `rank_name%i`='%s', `rank_point%i`='%d' WHERE `rank`='%s'", id, name, id, points, rank_name);
    mysql_query(Database, String, false);
    return 1;
}

// atualiza o rank
SERVER::rank_check(const rank_name[], const name[], points)
{
    if(points < 1 || !strlen(name) || strlen(name) > 24) return 0;

    remove_name_rank(rank_name, name);

	new query[130], String[130];
	mysql_format(Database, query, sizeof(query), "SELECT * FROM `ranks` WHERE `rank` = '%s'", rank_name);
	new Cache:result = mysql_query(Database, query);

	if(cache_is_valid(result))
	{
        new rows;
        cache_get_row_count(rows);
		if(rows > 0)
        {

            for(new i = 1; i < MAX_RANK; ++i)
            {
                format(String, sizeof(String), "rank_name%d", i);
    			cache_get_value_name(0, String, name__[i]);

                format(String, sizeof(String), "rank_point%d", i);
    			cache_get_value_name_int(0, String, points__[i]);

                if(!strlen(name__[i]))
                {
                    name__[i] = "Ninguem", points__[i] = 0;
                    format(String, sizeof(String), "UPDATE `ranks` SET `rank_name%i`='%s', `rank_point%i`='%d' WHERE `rank`='%s'", i, name__[i], i, points__[i], rank_name);
                    mysql_query(Database, String, false);
                }

                if(points > points__[i])
                {
                    for(new x = i; x < MAX_RANK; x++)
                    {
                        if(x == MAX_RANK-1) 
                            break;

                        set_rank_name_points(rank_name, x+1, name__[x], points__[x]);
                    }

                    format(name__[i], 24, name);
                    points__[i] = points;
                    set_rank_name_points(rank_name, i, name__[i], points__[i]);

                    new idp;
                    idp = IsPlayerOnlineEx(name);
                    if(idp != -1)
                    {
                        SendClientMessage(idp, COR_LIGHTBLUE, fmat_return("[SERVIDOR]: Voc� est� na Posi��o #%02d do Ranking de %s!", i, rank_name));
                    }
                    break;
                }
            }

			cache_unset_active();
			cache_delete(result);
            return 1;
		}
	}
    return 0;
}

// remove um nome do rank
stock remove_name_rank(const rank_name[], const rank_player[])
{

	new query[130];
	mysql_format(Database, query, sizeof(query), "SELECT * FROM `ranks` WHERE `rank` = '%s'", rank_name);
	new Cache:result = mysql_query(Database, query);


	if(cache_is_valid(result))
	{
        new rows;
        cache_get_row_count(rows);
		if(rows > 0)
        {
            new Nome[24], String[150];
            for(new i = 1; i < MAX_RANK; ++i)
            {
    			cache_get_value_name(0, fmat_return("rank_name%i", i), Nome);

                if(!strcmp(rank_player, Nome))
                {
                    format(String, sizeof(String), "UPDATE `ranks` SET `rank_name%i`='Ninguem', `rank_point%i`='0' WHERE `rank`='%s'", i, i, rank_name);
                    mysql_query(Database, String, false);
                }
            }

			cache_unset_active();
			cache_delete(result);
		}
	}
    return 1;
}

// verifica se um nome esta no rank
stock exists_name_rank(const rank_name[], const rank_player[])
{

	new query[130], sim = 0;
	mysql_format(Database, query, sizeof(query), "SELECT * FROM `ranks` WHERE `rank` = '%s'", rank_name);
	new Cache:result = mysql_query(Database, query);


	if(cache_is_valid(result))
	{
        new rows;
        cache_get_row_count(rows);
		if(rows > 0)
        {
            new Nome[24];
            for(new i = 1; i < MAX_RANK; ++i)
            {
    			cache_get_value_name(0, fmat_return("rank_name%i", i), Nome);

                if(!strcmp(rank_player, Nome))
                {
                    sim = 1;
                    break;
                }
            }

			cache_unset_active();
			cache_delete(result);
		}
	}
    return sim;
}

/*
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
*/

