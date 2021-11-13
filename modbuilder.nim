import os, sequtils, strutils, json

# David Eichendorf 2021 - 2022 Nim Minecraft Mod Builder

type
  ForgeLang* = object
    key*: string
    val*: string

type
  ForgeModItem* = object
    name*: string
    kind*: string
    path*: string

type
  ForgeMod* = object
    name*: string
    modid*: string
    mainclass*: string
    classpath*: string
    directory*: string
    registry*: seq[ForgeModItem]
    language*: seq[ForgeLang]

type
  ForgeModComponent* {.inheritable.} = object
    displayName*:string

type
  Block* = object of ForgeModComponent
    hardness*:float
    material*:string
    resistance*:float
    className*:string
    registryName*:string
    packagePath*:string
    maxStackSize*:int
    harvestLevel*:int
    harvestTool*:string
    sound*:string



var dump_mainclass = """
package %package%;

import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.eventbus.api.IEventBus;
import net.minecraftforge.fml.DistExecutor;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.javafmlmod.FMLJavaModLoadingContext;

@Mod(%mainclass%.MODID)
public class %mainclass%
{
    public static final String MODID = "%modid%";
    public static IEventBus MOD_EVENT_BUS;
    public %mainclass%() {
        MOD_EVENT_BUS = FMLJavaModLoadingContext.get().getModEventBus();
        registerCommonEvents();
        DistExecutor.runWhenOn(Dist.CLIENT, () -> %mainclass%::registerClientOnlyEvents);
    }
    public static void registerCommonEvents()
    {
        %registry%
    }
    public static void registerClientOnlyEvents()
    {
        
    }
}
"""
var dump_block_main = """
package %package%;

import net.minecraft.block.Block;
import net.minecraft.block.BlockRenderType;
import net.minecraft.block.BlockState;
import net.minecraft.block.material.Material;

public class %classname% extends Block
{
    public %classname%()
    {
        super(%properties%);
    }
    @Override
    public BlockRenderType getRenderType(BlockState blockState) {
        return BlockRenderType.MODEL;
    }
}
"""
var dump_block_startup = """
package %package%;

import net.minecraft.block.Block;
import net.minecraft.item.BlockItem;
import net.minecraft.item.Item;
import net.minecraft.item.ItemGroup;
import net.minecraftforge.event.RegistryEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;

public class StartupCommon
{
    public static %classname% theBlock;
    public static BlockItem theBlockItem;
    @SubscribeEvent
    public static void onBlocksRegistration(final RegistryEvent.Register<Block> blockRegisterEvent) {
        theBlock = (%classname%)(new %classname%().setRegistryName("%modid%", "%name%"));
        blockRegisterEvent.getRegistry().register(theBlock);
    }
    @SubscribeEvent
    public static void onItemsRegistration(final RegistryEvent.Register<Item> itemRegisterEvent) {
        Item.Properties itemProperties = new Item.Properties()
            .maxStackSize(64)
            .group(ItemGroup.BUILDING_BLOCKS);
        theBlockItem = new BlockItem(theBlock, itemProperties);
        theBlockItem.setRegistryName(theBlock.getRegistryName());
        itemRegisterEvent.getRegistry().register(theBlockItem);
    }
}
"""
var dump_block_startup_clientonly = """
package %package%;

import net.minecraft.client.renderer.RenderType;
import net.minecraft.client.renderer.RenderTypeLookup;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.event.lifecycle.FMLClientSetupEvent;

public class StartupClientOnly
{
    @SubscribeEvent
    public static void onClientSetupEvent(FMLClientSetupEvent event)
    {
        RenderTypeLookup.setRenderLayer(StartupCommon.theBlock, RenderType.getSolid());
    }
}
"""
var dump_pack_mcmeta = """
{
    "pack": {
        "description": "%desc%",
        "pack_format": 6,
        "_comment": "Created with Dev1lroot's ModMaker"
    }
}
"""
proc createFile(path, data: string) =
    if existsFile(path):
        echo "\t\t> File `"&path&"` skipped"
    else:
        writeFile(path, data)
        echo "\t\t+ File `"&path&"` created"

proc createFolder(path: string) =
    if existsDir(path):
        echo "\t\t> Folder `"&path&"` located"
    else:
        createDir(path)
        echo "\t\t+ Folder `"&path&"` created"

proc createProjectDirectory(m: ForgeMod) =
    echo "Creating project directories:"

    echo "\t# Common:"
    for p in ["java","resources"]:
        createFolder(m.directory&"src/main/"&p)

    echo "\t# Source:"
    createFolder(m.directory&"src/main/java/"&m.classpath.replace(".","/"))

    echo "\t# Resources:"
    createFile(m.directory&"src/main/resources/pack.mcmeta",dump_pack_mcmeta.replace("%desc%",m.modid))
    for p in ["assets/"&m.modid,"data","META-INF"]:
        createFolder(m.directory&"src/main/resources/"&p)

    echo "\t# Resources -> Assets:"
    for p in ["blockstates","models","textures","lang"]:
        createFolder(m.directory&"src/main/resources/assets/"&m.modid&"/"&p)

    echo "\t# Resources -> Assets -> Models:"
    for p in ["block","entity","item"]:
        createFolder(m.directory&"src/main/resources/assets/"&m.modid&"/models/"&p)

    echo "\t# Resources -> Assets -> Textures:"
    for p in ["block","entity","item","gui","model","particle"]:
        createFolder(m.directory&"src/main/resources/assets/"&m.modid&"/textures/"&p)

proc concatClasspath(path: seq[string]):string =
    var classpath:string
    for p in path:
        classpath &= p & "."
    while(classpath.contains("..")):
        classpath = classpath.replace("..",".")
    if $classpath[classpath.len-1] == ".":
        classpath = classpath[0..classpath.len-2]
    return classpath

proc createBlockAssets(m: ForgeMod, name: string) =
    echo "\t# Assets:"
    createFile(m.directory&"src/main/resources/assets/"&m.modid&"/blockstates/"&name&".json","{\"variants\":{\"\":{\"model\":\""&m.modid&":block/"&name&"\"}}}");
    createFile(m.directory&"src/main/resources/assets/"&m.modid&"/models/item/"&name&".json","{\"parent\": \""&m.modid&":block/"&name&"\"}");
    createFile(m.directory&"src/main/resources/assets/"&m.modid&"/models/block/"&name&".json","{\"parent\":\"block/cube\",\"textures\":{\"down\":\""&m.modid&":block/"&name&"\",\"up\":\""&m.modid&":block/"&name&"\",\"north\":\""&m.modid&":block/"&name&"\",\"east\":\""&m.modid&":block/"&name&"\",\"south\":\""&m.modid&":block/"&name&"\",\"west\":\""&m.modid&":block/"&name&"\",\"particle\":\"block/lapis_block\"}}");

proc createBlockSource(m: ForgeMod, b: Block) =
    echo "\t# Source:"
    var blockpath = m.directory&"src/main/java/"&concatClasspath(@[m.classpath,b.packagePath,b.registryName]).replace(".","/")
    createFolder(blockpath)

    var props = "Properties"
    props &= ".create(Material."&b.material&")"
    # if b.sound.len > 0:
    #     props &= ".sound(SoundType."&b.sound&")"
    if b.hardness > 0.0 or b.resistance > 0.0:
        props &= ".hardnessAndResistance(" & $b.hardness & "f, " & $b.resistance & "f)"
    if b.harvestLevel > 0:
        props &= ".harvestLevel(" & $b.harvestLevel & ")"
    # if b.harvestTool.len > 0:
    #     props &= ".harvestTool(ToolType." & $b.harvestTool & ")"

    createFile(blockpath&"/"&b.className&".java",dump_block_main
        .replace("%package%",concatClasspath(@[m.classpath,b.packagePath,b.registryName]))
        .replace("%classname%",b.className)
        .replace("%properties%",props))

    createFile(blockpath&"/StartupCommon.java",dump_block_startup
        .replace("%package%",concatClasspath(@[m.classpath,b.packagePath,b.registryName]))
        .replace("%classname%",b.className)
        .replace("%name%",b.registryName)
        .replace("%modid%",m.modid))

    createFile(blockpath&"/StartupClientOnly.java",dump_block_startup_clientonly
        .replace("%package%",concatClasspath(@[m.classpath,b.packagePath,b.registryName])))

proc create*(m: ForgeMod, n: Block): ForgeMod =
    var b = n

    # default values declaration
    #
    if 1 > b.displayName.len:
        b.displayName = capitalizeAscii(b.registryName.replace("_"," "))
    if 1 > b.className.len:
        b.className = capitalizeAscii(b.registryName.replace("_"," ")).replace(" ","")
    if 0 > b.resistance:
        b.resistance = 1;
    if 0 > b.hardness:
        b.hardness = 1
    if 1 > b.material.len:
        b.material = "ROCK"
    if 1 > b.sound.len:
        b.sound = "STONE"
    if 0 > b.harvestLevel:
        b.harvestLevel = 1
    if 1 > b.harvestTool.len:
        b.harvestTool = "PICKAXE"
    if 1 > b.maxStackSize:
        b.maxStackSize = 64
    #
    # ==========================

    echo "Creating Block: ",b.displayName
    var o = ForgeModItem(name: b.registryName, kind: "block", path: b.packagePath)
    var u = m
    u.registry.add o
    u.language.add ForgeLang(key: concatClasspath(@["block",m.modid,b.registryName]), val: b.displayName)
    createBlockSource(u, b)
    createBlockAssets(u, b.registryName)
    return u

proc createMeta(m: ForgeMod) =
    echo "Creating mods.toml"
    createFile(m.directory&"src/main/resources/META-INF/mods.toml","modLoader=\"javafml\"\nloaderVersion=\"[35,)\"\nlicense=\"CCBY 3.0\"\n[[mods]]\nmodId=\""&m.modid&"\"\nversion=\"${file.jarVersion}\"\ndisplayName=\""&m.name&"\"\ndescription='''Created With Nim ModMaker by Dev1lroot'''")

proc createMainClass(m: ForgeMod) =
    echo "Creating the Main class:"
    var main = dump_mainclass.replace("%package%",m.classpath).replace("%modid%",m.modid).replace("%mainclass%",m.mainclass)
    if m.registry.len == 0:
        main = main.replace("%registry%","");
    else:
        var registry: string
        for item in m.registry:
            echo "\t# Registering component: <",item.kind,">",concatClasspath(@[item.path,item.name])
            if item.kind == "block":
                registry &= "MOD_EVENT_BUS.register(" & concatClasspath(@[m.classpath,item.path,item.name,"StartupCommon","class"]) & ");\n"
        main = main.replace("%registry%",registry);

    createFile(m.directory&"src/main/java/"&m.classpath.replace(".","/")&"/"&m.mainclass&".java",main)

proc createLang(m: ForgeMod) =
    echo "Creating en_us.json"
    var s = parseJson("{}")
    for r in m.language:
        s[r.key] = newJString(r.val)
    createFile(m.directory&"src/main/resources/assets/"&m.modid&"/lang/en_us.json",pretty(s))

proc init*(m: ForgeMod) =
    createProjectDirectory(m)

proc build*(m: ForgeMod) =
    createMainClass(m)
    createMeta(m)
    createLang(m)

# createAssetsDirectory("hitech_assets")
# for mineral in ["petalite","lepidolite","rutile","ilmenite","olivine","erythrite","dolomite","skutterudite","sphalerite"]:
#     createBlockAssets("hitech_assets", "mineral_"&mineral)

