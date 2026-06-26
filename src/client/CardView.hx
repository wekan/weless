package;

import haxe.ui.containers.VBox;
import haxe.ui.extensions.Draggable;
import shared.Models;

/**
	A single draggable Kanban card.

	Implementing `haxe.ui.extensions.Draggable` injects the `draggable` property
	and the `onDragStart` / `onDrag` / `onDragEnd` events used by `MainView` to
	implement drag-and-drop between columns.
**/
@:build(haxe.ui.ComponentBuilder.build("assets/card-view.xml"))
class CardView extends VBox implements Draggable {
	public var model(default, null):Card;

	public function new(model:Card) {
		super();
		this.model = model;
		cardTitle.text = model.title;
		draggable = true;
	}
}
