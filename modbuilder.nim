import os, sequtils

# David Eichendorf 2021 - 2022

proc createAssetsDirectory(modid: string) =
    echo "Создание директорий"
    for dir in ["assets","assets/"&modid,"assets/"&modid&"/blockstates","assets/"&modid&"/models","assets/"&modid&"/models/block","assets/"&modid&"/models/item","assets/"&modid&"/models/entity","assets/"&modid&"/textures","assets/"&modid&"/textures/block","assets/"&modid&"/textures/item","assets/"&modid&"/textures/entity","assets/"&modid&"/textures/gui","assets/"&modid&"/textures/model","assets/"&modid&"/textures/particle","assets/"&modid&"/lang"]:
        if existsDir(dir):
            echo "> Папка `"&dir&"` найдена"
        else:
            createDir(dir)
            echo "> Папка `"&dir&"` не найдена, создана заново"

proc createBlockAssets(modid, name: string) =
    echo "> Создаем файл `assets/"&modid&"/blockstates/"&name&".json`"
    writeFile("assets/"&modid&"/blockstates/"&name&".json","{\"variants\":{\"\":{\"model\":\""&modid&":block/"&name&"\"}}}");
    echo "> Создаем файл `assets/"&modid&"/models/item/"&name&".json`"
    writeFile("assets/"&modid&"/models/item/"&name&".json","{\"parent\": \""&modid&":block/"&name&"\"}");
    echo "> Создаем файл `assets/"&modid&"/models/block/"&name&".json`"
    writeFile("assets/"&modid&"/models/block/"&name&".json","{\"parent\":\"block/cube\",\"textures\":{\"down\":\""&modid&":block/"&name&"\",\"up\":\""&modid&":block/"&name&"\",\"north\":\""&modid&":block/"&name&"\",\"east\":\""&modid&":block/"&name&"\",\"south\":\""&modid&":block/"&name&"\",\"west\":\""&modid&":block/"&name&"\",\"particle\":\"block/lapis_block\"}}");
