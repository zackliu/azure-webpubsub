/*---------------------------------------------------------------------------------------------
*  Copyright (c) Microsoft Corporation. All rights reserved.
*  Licensed under the MIT License. See License.txt in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import { type EventHandler } from "@azure/arm-webpubsub";
import { type TreeElementBase} from "@microsoft/vscode-azext-utils";
import { createContextValue } from "@microsoft/vscode-azext-utils";
import { type ViewPropertiesModel } from "@microsoft/vscode-azureresources-api";
import * as vscode from 'vscode';
import { type EventHandlersItem } from "./EventHandlersItem";
import { localize } from "../../../utils";

export class EventHandlerItem implements TreeElementBase {
    static readonly contextValue: string = 'webPubSubHubEventHandlerItem';
    static readonly contextValueRegExp: RegExp = new RegExp(EventHandlerItem.contextValue);

    constructor(public readonly eventHandlersItem: EventHandlersItem, public readonly eventHandler: EventHandler, public readonly priority: number) { }

    async getChildren(): Promise<TreeElementBase[]> { return []; }

    getTreeItem(): vscode.TreeItem {
        return {
            label: localize("eventHandlerWithOrder", "Event Handler {0}", this.priority),
            iconPath: new vscode.ThemeIcon("send"),
            contextValue: createContextValue([EventHandlerItem.contextValue]),
            collapsibleState: vscode.TreeItemCollapsibleState.None,
            tooltip: new vscode.MarkdownString(`\
**Url Template**: ${this.eventHandler.urlTemplate}\n\n\
**System Events**: ${this.eventHandler.systemEvents}\n\n\
**User Event Pattern**: ${this.eventHandler.userEventPattern}`)
        };
    }

    viewProperties: ViewPropertiesModel = {
        data: this.eventHandler,
        label: `Event Handler ${this.priority}`
    };
}
