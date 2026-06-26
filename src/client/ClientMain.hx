package;

import haxe.ui.Toolkit;
import haxe.ui.core.Screen;

/**
	HTML5/JS client entry point.

	Initialises the HaxeUI toolkit and mounts the Kanban `MainView` full-screen.
**/
class ClientMain {
	public static function main() {
		Toolkit.init();

		final main = new MainView();
		main.percentWidth = 100;
		main.percentHeight = 100;
		Screen.instance.addComponent(main);
	}
}
