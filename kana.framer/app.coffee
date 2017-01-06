
kanaLayers = Framer.Importer.load("imported/kana@2x")

#创建新Layer
container = new Layer
	width: Screen.width 
	height: Screen.height 
	backgroundColor:"#fff"
	
container.center()

#TODO 上拉进入五十音图页
bottomButton = new Layer
	width: Screen.width
	height: 44
bottomButton.centerX()
bottomButton.backgroundColor = Color.gray(0.5, 0.1)
bottomButton.y = Screen.height - 44
bottomButton.visible = false
bottomButton.on Events.Click, ->
	bottomButton.visible = false
	kanaLayers.Test_scene.visible = false
	kanaLayers.Kana_scene.visible = true
	kanaLayers.Kana_scene.superLayer = container
	kanaLayers.Kana_scene.center()
	kanaLayers.Kana_scene.draggable = true
	topButton.visible = true
	
#TODO 下拉返回测试页
topButton = new Layer
	width: Screen.width
	height: 88
topButton.centerX()
topButton.y = 0
topButton.visible = false
topButton.backgroundColor = Color.gray(0.5, 0.1)
topButton.on Events.Click, ->
	topButton.visible = false
	bottomButton.visible = true
	kanaLayers.Test_scene.visible = true
	kanaLayers.Kana_scene.visible = false
	
#显示Launch image
kanaLayers.LaunchImage.visible = true
kanaLayers.LaunchImage.superLayer = container
kanaLayers.LaunchImage.center()

#进入测试页
Utils.delay 2, -> 
	kanaLayers.LaunchImage.visible = false
	kanaLayers.Test_scene.visible = true
	kanaLayers.Test_scene.superLayer = container
	kanaLayers.Test_scene.center()
	kanaLayers.Test_scene.draggable = true
	bottomButton.visible = true



#答题正确效果
#答题错误效果
