package;

import haxe.ui.containers.VBox;
import haxe.ui.events.DragEvent;
import shared.Models;

/**
	The top-level Kanban board view and drag-and-drop controller.

	Built from `assets/main-view.xml`, which provides:
	  - `boardContainer` (HBox)  — holds the columns
	  - `addColumnButton` (Button)
	  - `boardScroll` (ScrollView)

	It renders the `BoardStore`, and on a card drag-end works out the target
	column and insertion index by hit-testing, asks the store to move the card,
	then re-renders.
**/
@:build(haxe.ui.ComponentBuilder.build("assets/main-view.xml"))
class MainView extends VBox {
	final store:BoardStore;
	final columnViews:Array<ColumnView> = [];

	public function new(?store:BoardStore) {
		super();
		this.store = store != null ? store : new BoardStore();
		addColumnButton.onClick = _ -> promptAddColumn();
		render();
	}

	/** Rebuild every column and card from the current store state. **/
	public function render():Void {
		columnViews.resize(0);
		boardContainer.removeAllComponents();
		for (data in store.columns) {
			final col = new ColumnView(data, this);
			columnViews.push(col);
			boardContainer.addComponent(col);
		}
	}

	/** Wire a freshly-created card for drag-and-drop. **/
	public function registerCard(view:CardView, column:ColumnView):Void {
		view.onDragStart = _ -> view.addClass("kanban-card-dragging");
		view.onDragEnd = _ -> {
			view.removeClass("kanban-card-dragging");
			handleDrop(view);
		};
	}

	function handleDrop(view:CardView):Void {
		final cx = view.screenLeft + view.width / 2;
		final cy = view.screenTop + view.height / 2;

		final target = columnUnder(cx, cy);
		if (target == null) {
			// Dropped outside any column: snap back by re-rendering.
			render();
			return;
		}

		final index = insertionIndex(target, view, cy);
		store.moveCard(view.model, target.model.column.id, index);
		render();
	}

	/** The column whose bounds contain the given screen point, if any. **/
	function columnUnder(screenX:Float, screenY:Float):Null<ColumnView> {
		for (col in columnViews) {
			if (col.hitTest(screenX, screenY)) {
				return col;
			}
		}
		return null;
	}

	/** Where in `target` a card dropped at screen-y `cy` should be inserted. **/
	function insertionIndex(target:ColumnView, dragged:CardView, cy:Float):Int {
		final container = target.cards();
		var index = 0;
		for (i in 0...container.numComponents) {
			final child = container.getComponentAt(i);
			if (child == dragged) {
				continue;
			}
			final mid = child.screenTop + child.height / 2;
			if (cy < mid) {
				return index;
			}
			index++;
		}
		return index;
	}

	public function promptAddColumn():Void {
		final title = prompt("New list name:", "New List");
		if (title != null && StringTools.trim(title).length > 0) {
			store.addColumn(StringTools.trim(title));
			render();
		}
	}

	public function promptAddCard(column:ColumnView):Void {
		final title = prompt("New card title:", "New card");
		if (title != null && StringTools.trim(title).length > 0) {
			store.addCard(column.model.column.id, StringTools.trim(title));
			render();
		}
	}

	/** Small cross-target text prompt (uses the browser prompt on HTML5/JS). **/
	function prompt(message:String, defaultValue:String):Null<String> {
		#if js
		return js.Browser.window.prompt(message, defaultValue);
		#else
		return defaultValue;
		#end
	}
}
