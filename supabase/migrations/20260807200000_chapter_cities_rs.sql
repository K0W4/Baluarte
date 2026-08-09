-- Cidades dos Capítulos do Rio Grande do Sul.
--
-- Complementa o seed anterior, que trouxe só nome e número. Casadas pelo número
-- dentro da UF, que é a chave real do registro -- os 51 bateram exatamente, sem
-- sobra de nenhum lado.
--
-- Uma correção de grafia: a relação trazia "Tôrres" para o Capítulo nº 451. O
-- município se chama "Torres" desde a reforma ortográfica de 1971. A busca acharia
-- os dois de qualquer jeito (o índice ignora acento), mas a cidade aparece na tela,
-- e o catálogo é registro de lugar real.

begin;

update public.chapter c
   set city = v.city
  from (values
    (196, 'Santa Maria'),
    (805, 'Lajeado'),
    (821, 'Cachoeira do Sul'),
    (902, 'Santa Cruz do Sul'),
    (906, 'Venâncio Aires'),
    (1268, 'São Pedro do Sul'),
    (46, 'Porto Alegre'),
    (77, 'Porto Alegre'),
    (340, 'Canoas'),
    (465, 'Porto Alegre'),
    (494, 'Porto Alegre'),
    (514, 'Cachoeirinha'),
    (592, 'São Leopoldo'),
    (656, 'Viamão'),
    (1030, 'Charqueadas'),
    (451, 'Torres'),
    (493, 'Tramandaí'),
    (630, 'Osório'),
    (92, 'Caxias do Sul'),
    (146, 'Caxias do Sul'),
    (597, 'Flores da Cunha'),
    (967, 'Farroupilha'),
    (1027, 'Canela'),
    (1063, 'Caxias do Sul'),
    (1111, 'Caxias do Sul'),
    (1189, 'Bento Gonçalves'),
    (1247, 'Vacaria'),
    (237, 'Ijuí'),
    (306, 'Santo Ângelo'),
    (382, 'Cruz Alta'),
    (580, 'Santa Rosa'),
    (853, 'Horizontina'),
    (243, 'Passo Fundo'),
    (635, 'Soledade'),
    (964, 'Carazinho'),
    (983, 'Marau'),
    (1132, 'Tapejara'),
    (1198, 'Erechim'),
    (1209, 'Serafina Corrêa'),
    (1250, 'Ibirubá'),
    (3, 'Pelotas'),
    (354, 'Rio Grande'),
    (858, 'Piratini'),
    (95, 'Uruguaiana'),
    (384, 'Alegrete'),
    (575, 'São Borja'),
    (1089, 'Itaqui'),
    (91, 'Bagé'),
    (433, 'Santana do Livramento'),
    (952, 'Dom Pedrito'),
    (1206, 'Rosário do Sul')
  ) as v(number, city)
 where c.number = v.number
   and c.uf = 'RS';

commit;
