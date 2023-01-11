import { LightningElement, api, track } from 'lwc';
import fetchSearchData from '@salesforce/apex/GeneralService.fetchSearchData';
import fetchDefaultRecord from '@salesforce/apex/GeneralService.fetchDefaultRecord';
import fetchDefaultRecords from '@salesforce/apex/GeneralService.fetchDefaultRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import NO_RECORDS_FOUND_MSG from '@salesforce/label/c.LOOKUP_RECORDSEARCHSELECT_ERROR_MSG';

export default class LookupRecordSearchSelect extends LightningElement {
    /***************************************************************************************************
    PUBLIC PROPERTIES
    ***************************************************************************************************/
    @api objectApiName = 'Account';
    @api placeholder = 'Search..';
    @api Label;
    @api selectedRecords = [];
    @api selectedRecordobj = [];
    @api searchRecordIds = [];
    @api maxSelections;
    @api inputrequired=false;
    @api selectedrecordid ='';
    @api selectedrecordName='';
    @api selectedRecordNames = [];

    /***************************************************************************************************
    PRIVATE PROPERTIES
    ***************************************************************************************************/
    searchRecords = []; // arr to store queried results
    noRecordsFound = false; // boolean to show error message on UI
    isSearchLoading = false;
    searchKey;
    showDropDown =false;
    delayTimeout;
    disableSearchBox;
    //noRecordsFoundMsg = NO_RECORDS_FOUND_MSG;

    noRecordsFoundMsg = 'No records found';

    get
    isSingleSelection(){
        try{
            return (this.maxSelections == 1) ? true : false;
        }catch(err){
            alert('JS Error: ' + 'isMultiSelection');
        }
    }

    connectedCallback(){
        console.log('selectedRecordNames::'+this.selectedRecordNames);
        console.log(this.selectedRecords);
        console.log(this.selectedRecords != '');
        if(this.selectedrecordid != ''){
           fetchDefaultRecord({ recordId: this.selectedrecordid , 'sObjectApiName' : this.objectApiName })
           .then((result) => {
               if(result != null){
                   this.selectedrecordName = result.Name;
                   this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
               }
           })
           .catch((error) => {
               this.error = error;
               this.selectedrecordName = {};
           });
        }else if(this.selectedRecords != ''){
            fetchDefaultRecords({ recordIds : this.selectedRecords , 'sObjectApiName' : this.objectApiName })
           .then((result) => {
               if(result != null){
                    this.selectedRecordobj = result;
                    console.log(this.selectedRecordobj);
                    console.log(JSON.stringify(this.selectedRecordobj));
                    this.selectedRecords = this.selectedRecordobj.map(s=>s.Id);
                    this.selectedRecordNames = this.selectedRecordobj.map(s=>s.Name);
                    console.log(this.selectedRecords);
               }
           })
           .catch((error) => {
               this.error = error;
               this.selectedRecordobj = {};
           });
            
        }
   }

    checkMaximumSelections() { //todo: where is this used???
        if (this.maxSelections) {
            let maximum = parseInt(this.maxSelections);
            if (this.selectedRecordobj.length >= maximum) {
                this.disableSearchBox = true;
            }
            else {
                this.disableSearchBox = false;
            }
        }
    }

    /***************************************************************************************************
    HANDLE FUNCTIONS
    ***************************************************************************************************/

    /**
     * Handles update searchKey property on input field change  
     */
    handleKeyChange(event) {
        // Do not update the reactive property as long as this function is //todo: function is?
        this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchKey;
            this.searchField();
        }, 300);
    }

    /*COMMON HELPER METHOD STARTED*/

    handelSelectRecordHelper(){
        this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');

        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-show');
        searchBoxWrapper.classList.add('slds-hide');

        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-hide');
        pillDiv.classList.add('slds-show');     
    }

    /**
     * Handles toggle lookup result section on UI
     */
    handleToggleResult(event) {
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');

        switch (whichEvent) {
            case 'searchInputField':
                clsList.add('slds-is-open');
                this.searchField();
                break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');
                break;
        }
    }

    handleBlur(event){
        try{
            //return;
            window.setTimeout(
                () => {
                    try{
                        this.showDropDown = false;
                        this.refreshSearchBox();
                    }catch(err){
                        alert('JS Error: ' + 'lwcAddReviewers > handleBlur > window.setTimeOut');
                    } 
                }, 700
            );
        }catch(err){
            alert('JS Error: ' + 'lwcAddReviewers > handleBlur');
        }
    }

    refreshSearchBox(){
        try{
            let element = this.template.querySelector(".searchBox");
            element.value = "";
        }catch(err){
            alert('JS Error: ' + 'lwcAddReviewers > refreshSearchBox');
        }
        
    }

    /**
     * Handles record unselection on UI
     */
    removeRecord(event) {
        let selectRecId = [];
        let selectRec = [];
        let selectRecNames=[];
        for (let i = 0; i < this.selectedRecordobj.length; i++) {
            console.log('event.detail.name--------->' + event.detail.name);
            console.log('this.selectedRecordobj[i].Id--------->' + this.selectedRecordobj[i].Id);
            if (event.detail.name !== this.selectedRecordobj[i].Id)
            {
                selectRec.push(this.selectedRecordobj[i]);
                selectRecId.push(this.selectedRecordobj[i].Id);
                selectRecNames.push(this.selectedRecordobj[i].Name);
            }
        }

        if(this.maxSelections == 1){
            this.handelSelectRecordHelper();
        }

        this.selectedRecordobj = [...selectRec];
        this.selectedRecords = [...selectRecId];
        this.selectedRecordNames = [...selectRecNames];
        console.log('this.selectedRecordobj----------->' + this.selectedRecordobj);
        let selRecords = this.selectedRecordobj;
        this.checkMaximumSelections();
        const selectedEvent = new CustomEvent('selected', { detail: { selRecords }, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    /**
     * Handles record selection on UI
     */
    setSelectedRecord(event) {
        var recId = event.target.dataset.id;
        var selectName = event.currentTarget.dataset.name;
        let newsObject = this.searchRecords.find(data => data.Id === recId);
        this.showDropDown = false;
        //this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');
        let selRecords = this.selectedRecordobj;
        this.searchKey ='';
        /*this.template.querySelectorAll('lightning-input').forEach(each => {
            each.searchKey = '';
        });*/
        this.checkMaximumSelections();
        if(this.maxSelections == 1){
            this.handelSelectRecordHelper();
            this.selectedrecordid =recId;
            this.selectedrecordName=selectName;
        }else{
            this.selectedRecordobj.push(newsObject);
            this.selectedRecords.push(recId);
            this.selectedRecordNames.push(selectName);
        }
        console.log(JSON.stringify(this.selectedRecordobj));
        const selectedEvent = new CustomEvent('selected', { detail: { selRecords }, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    handleRemove(){
        this.searchKey = '';    
        this.selectedrecordid ='';
        this.selectedrecordName='';
        
        // remove selected pill and display input field again 
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
         searchBoxWrapper.classList.remove('slds-hide');
         searchBoxWrapper.classList.add('slds-show');
         this.disableSearchBox =false;
    
         const pillDiv = this.template.querySelector('.pillDiv');
         pillDiv.classList.remove('slds-show');
         pillDiv.classList.add('slds-hide');
      }

    /***************************************************************************************************
    HELPER/UTIL FUNCTIONS
    ***************************************************************************************************/

    /**
     * Function to fetch data from back-end
     */
    searchField() {
        /*var alreadyselectedIds = [];
        this.selectedRecordobj.forEach(rec=>{
            alreadyselectedIds.push(rec.Id);
        })*/

        fetchSearchData({ objectApiName: this.objectApiName, searchKey: this.searchKey, selectedRecIds: this.selectedRecords, searchRecordIds : this.searchRecordIds })
            .then(result => {
                this.searchRecords = result;
                this.isSearchLoading = false;
                const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
                const clsList = lookupInputContainer.classList;
                clsList.add('slds-is-open');
                this.showDropDown =true;
                if (this.searchKey.length > 0 && result.length == 0) {
                    this.noRecordsFound = true;
                } else {
                    this.noRecordsFound = false;
                }
            }).catch(error => {
                console.log(error);
            });
    }
}