import { LightningElement, api } from 'lwc';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { NavigationMixin } from 'lightning/navigation';

export default class ScreenFlowNavigateToRecordOnFinish extends NavigationMixin(LightningElement) {
    @api recordId;
    triggered = false;

    @api
    get recordLink() {
        return `/${this.recordId||''}`;
    }

    renderedCallback() {
        if(!this.triggered) {
            this.triggered = true;
            if(!this.recordId) {
                return; // do nothing if there is no record id provided
            }
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            });
            console.log("navigate finish");
            const navigateFinishEvent = new FlowNavigationFinishEvent();
            this.dispatchEvent(navigateFinishEvent);
        }
    }
}