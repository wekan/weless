package;

import haxe.ui.containers.VBox;
import shared.Models;

/**
	A single Kanban column ("list"): a titled, vertical stack of `CardView`s with
	an "add a card" button at the bottom. Rendering and drag wiring are delegated
	back to the owning `MainView` controller.
**/
@:build(haxe.ui.ComponentBuilder.build("assets/column-view.xml"))
class ColumnView extends VBox {
	public var model(default, null):ColumnData;

	final controller:MainView;

	public function new(model:ColumnData, controller:MainView) {
		super();
		this.model = model;
		this.controller = controller;

		columnTitle.text = model.column.title;
		for (card in model.cards) {
			addCardView(card);
		}
		addCardButton.onClick = _ -> controller.promptAddCard(this);
	}

	/** Create a `CardView` for `card`, register it for drag-and-drop, and append it. **/
	public function addCardView(card:Card):CardView {
		final view = new CardView(card);
		controller.registerCard(view, this);
		cardsContainer.addComponent(view);
		return view;
	}

	/** The vertical stack that holds the cards (used for hit-testing drops). **/
	public function cards():VBox {
		return cardsContainer;
	}
}
