import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRecentlyFiles from '@salesforce/apex/ContentFilePickerController.getRecentlyFiles';
import getFilesOwnedByMe from '@salesforce/apex/ContentFilePickerController.getFilesOwnedByMe';
import getFilesSharedWithMe from '@salesforce/apex/ContentFilePickerController.getFilesSharedWithMe';
import getFollowingFiles from '@salesforce/apex/ContentFilePickerController.getFollowingFiles';
import createContentDocumentLinks from '@salesforce/apex/ContentFilePickerController.createContentDocumentLinks';

const DEFAULT_NAVIGATION_TREE = [
    { label : 'Owned by Me', action: 'getFilesOwnedByMe', selected: true },
    { label : 'Shared with Me', action: 'getFilesSharedWithMe', selected: false },
    { label : 'Recent', action: 'getRecentlyFiles', selected: false  },
    { label : 'Following', action: 'getFollowingFiles', selected: false  },
    { label : 'Related Files', action: 'getRelatedFiles', selected: false  }
]

export default class ContentFilePicker extends LightningElement {
    isLoading = true;

    @api recordId;
    @api objectName;

    @track selectedFileIds = new Set();
    @track fileList = [];
    @track navTreeItems = JSON.parse(JSON.stringify(DEFAULT_NAVIGATION_TREE));

    get pickerModal() {
        return this.template.querySelector('.picker-modal');
    }

    async onClickAddFiles () {
        this.navTreeItems = JSON.parse(JSON.stringify(DEFAULT_NAVIGATION_TREE));
        this.fileList = [];
        this.isLoading = true;
        this.pickerModal.open();
        this.fileList = await getFilesOwnedByMe();
        this.isLoading = false;
    }

    handleUploadFinished () {
        this.dispatchEvent(new CustomEvent('uploadsuccess'));
    }

    async handleNavItemClick (event) {
        const clickedItemName = event.currentTarget.dataset.name;
        const action = event.currentTarget.dataset.action;

        for(let item of this.navTreeItems) {
            if (clickedItemName == item.label) {
                item.selected = true
            } else {
                item.selected = false
            }
        }
        this.isLoading = true;
        switch (action) {
            case 'getFilesOwnedByMe': 
                this.fileList = await getFilesOwnedByMe();
                break;
            case 'getFilesSharedWithMe':
                this.fileList = await getFilesSharedWithMe();
                break;
            case 'getRecentlyFiles':
                this.fileList = await getRecentlyFiles();
                break;
            case 'getFollowingFiles':
                this.fileList = await getFollowingFiles();
                break;
            case 'getRelatedFiles':
                // this.filelist = await getRelatedList();
                break;
            default:
        }
        this.isLoading = false;
    }

    handleCheckbox (event) {
        const target = event.currentTarget;
        const id = target.dataset.id;

        if (target.checked) {
            this.selectedFileIds.add(id);
        } else {
            this.selectedFileIds.delete(id);
        }
    }

    onClickCancel () {
        this.close();
    }

    async onClickAdd () {
        try {
            await createContentDocumentLinks({
                selectedFileIds: [...this.selectedFileIds],
                recordId: this.recordId
            });
            this.close();
            let successFileTotal = this.selectedFileIds.size; 
            this.dispatchEvent(
                new ShowToastEvent({
                    message: `${successFileTotal} ${successFileTotal > 1 ? 'files were' : 'file was'} added to the ${this.objectName}`,
                    variant: 'success'
                })
            );
        } catch(error) {
            window.console.log(error.message);
        }
    }

    close() {
        this.pickerModal.close();
    }
}