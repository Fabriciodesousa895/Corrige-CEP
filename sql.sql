CREATE OR REPLACE NONEDITIONABLE PROCEDURE API_CEP(   P_CEP IN VARCHAR,
                                                      P_CIDADE IN VARCHAR,
                                                      IBGE IN VARCHAR,
                                                      P_UF IN VARCHAR,
                                                      P_BAIRRO IN VARCHAR,
                                                      P_COMPLEMENTO IN VARCHAR )
IS
 V_COUNT INT;
 V_COUNT_1 INT;
 V_COUNT_2 INT;
 V_COUNT_3 INT;
 V_NOME VARCHAR(100);
 V_NOME_1 VARCHAR(100);
 V_CORRIGE VARCHAR(2);
 V_ID_CID INT;
 V_API_CEP VARCHAR(2);

BEGIN
          --VERIFICANDO PARAMETRO NA TABELA PREFERENCES
          SELECT CORRIGE_CID INTO V_CORRIGE FROM PREFERENCES;
          SELECT VIA_CEP INTO V_API_CEP FROM PREFERENCES;

IF NVL(V_API_CEP,'N') = 'S' THEN
                          <<CORRIGE_CIDADE_NOME>>
          SELECT COUNT(*) INTO V_COUNT_2 FROM CIDADE WHERE COD_DOMICILIO_FISCAL = IBGE;

            ---SE O COD_DOMICILIO_FISCAL EXISTE NA TABELA CIDADE;
            IF V_COUNT_2 > 0 THEN
              SELECT NOME INTO V_NOME FROM CIDADE WHERE COD_DOMICILIO_FISCAL = IBGE;
              --SE O NOME CADASTRADADO FOR DIFERENTE DO RETORNO DAS API;
              IF UPPER(V_NOME) <> UPPER(P_CIDADE) THEN
                --SE O PARAMETRO DE CORRIGIR REGISTRO ESTIVER ATIVO ELE ALTERA O NOME
                IF NVL(V_CORRIGE,'N') = 'S' THEN
                  UPDATE CIDADE SET NOME = UPPER(P_CIDADE) WHERE COD_DOMICILIO_FISCAL = IBGE;
                END IF; 
              END IF;
                 
             END IF;
                      <<CORRIGE_CIDADE_IBGE>>   
                               
            IF V_COUNT_2 = 0 THEN
                 ---*QUANDO O COD_DOMICILIO_FISCAL NÃO EXISTE ELE PROCURA PELO NOME
                 SELECT COUNT(*) INTO V_COUNT_3 FROM CIDADE WHERE NLSSORT(UPPER(NOME),'NLS_SORT=GENERIC_M') =  NLSSORT(UPPER(P_CIDADE),'NLS_SORT=GENERIC_M');
                 --QUANDO O NOME DA CIDADE EXISTE
                 IF V_COUNT_3 > 0 THEN
                   IF NVL(V_CORRIGE,'N') = 'S' THEN
                     UPDATE CIDADE SET COD_DOMICILIO_FISCAL = IBGE WHERE UPPER(NOME) = UPPER(P_CIDADE);
                      COMMIT;
                   END IF;
                 END IF;
            END IF;
                --QUANDO A CIDADE NÃO ESTÁ CADASTRADA
                 <<INSERI_CIDADE_IBGE>>
                 IF V_COUNT_3  = 0 THEN
                   INSERT INTO CIDADE(NOME,COD_DOMICILIO_FISCAL) VALUES(P_CIDADE,IBGE);
                   COMMIT;
                 END IF;
            
            
                  <<VERIFICA_CEP>>
            SELECT COUNT(*) INTO V_COUNT_1 FROM CEP C WHERE REPLACE(REPLACE(C.CEP,'-',''),'.','') = REPLACE(REPLACE(P_CEP,'-',''),'.','') ;
            --CASO O CEP NÃO EXISTA NA TABELA CEP, É INSERIDO O REGISTRO
            IF  V_COUNT_1 = 0 THEN
              SELECT ID INTO V_ID_CID  FROM CIDADE WHERE COD_DOMICILIO_FISCAL = IBGE;
              INSERT INTO CEP(CEP,BAIRRO,UF,ID_CIDADE,COMPLEMENTO) VALUES(REGEXP_REPLACE(P_CEP,'[^a-zA-Z0-9\s]',''),UPPER(P_BAIRRO),P_UF,V_ID_CID,REGEXP_REPLACE(UPPER(P_COMPLEMENTO),'[^[:alnum:]]',''));
              COMMIT;
            END IF;   

END IF;

END;
