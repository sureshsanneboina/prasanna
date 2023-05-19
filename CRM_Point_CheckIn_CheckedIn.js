({
	init : function(cmp, evt, hlp) {
        var filterValue = cmp.get("v.filter");
        var columns = [
            {label:"Appt Time",labelVisible:'true'},
            {label:"Time In",labelVisible:'true'},
            {label:"Wait Time",labelVisible:'true'},
            {label:"Customer",labelVisible:'true'},
            {label:"Associate",labelVisible:'true'},
            {label:"ETA",labelVisible:'true'},
            {label:"Assign",labelVisible:'false'},
            {label:"Cancel",labelVisible:'false'}
        ];
		
		if(cmp.get('displayProgressBar')){
			columns.push({label:"Progress",labelVisible:'true'});
		}
		
        cmp.set('v.columns',columns);
		var action = cmp.get("c.getAllData");
		action.setCallback(this, function(response){
			if(response.getState() === "SUCCESS"){
                var mainList = response.getReturnValue().CustomersCheckedInList;
                if(typeof mainList != 'undefined'){
                    if(filterValue!='all'){
                        if(filterValue=='appraisal'){
                            mainList = hlp.filterArray(mainList,true);
                        } else{
                            mainList = hlp.filterArray(mainList,false);
                        }
                    }
                    mainList = hlp.bubbleSortWaittime(mainList);
                    mainList = hlp.bubbleSortAppoinment(mainList);
                    mainList = hlp.bubbleSortVisitPurpose(mainList,'Curbside');
                    mainList = hlp.bubbleSortETA(mainList);
                }
				cmp.set("v.CustomersCheckedInList", mainList);
                cmp.set("v.CurrentUserDetails", response.getReturnValue().CurrentUserDetails);
                cmp.set("v.UserActiveLocation", response.getReturnValue().UserActiveLocation);
                var assignableAssociates = response.getReturnValue().assignableAssociates;
                cmp.set("v.assignableAssociates", assignableAssociates);
                cmp.set("v.CurrentUserDetailsLoaded", true);
                const GLANCEABLEACTIVELOCATION = $A.get("$Label.c.GlanceableViewOnPoint");
                if(GLANCEABLEACTIVELOCATION && (GLANCEABLEACTIVELOCATION.includes('All') || GLANCEABLEACTIVELOCATION.includes(cmp.get("v.CurrentUserDetails.Region__c")) || GLANCEABLEACTIVELOCATION.includes(cmp.get("v.CurrentUserDetails.Active_Location__c")))){
                    cmp.set("v.glanceableViewEnabled",true);
                }
			}
		});
		$A.enqueueAction(action);
	},

	handleRefreshEvent : function (component, event, helper) {
		var eventLocations = event.getParam('locations');
		var userActiveLocation = component.get("v.CurrentUserDetails").Active_Location__c;

		if (eventLocations.includes(userActiveLocation)) {
			console.log('Refreshing walkins...');
			var initMethod = component.get('c.init');
			$A.enqueueAction(initMethod);
		}
		else {
			console.log('Ignoring refresh event as it is not for the active location');
		}
	},

    removeFromWaitList : function(cmp, evt, hlp) {
        cmp.set("v.reloading",true);
        hlp.removeFromWaitList(cmp,evt, hlp);
	},
    addToWaitListOLD : function (cmp, evt, hlp) {
    var createRecordEvent = $A.get("e.force:createRecord");
    createRecordEvent.setParams({
        "entityApiName": "CRM_WalkInCustomer__c"
    });
    createRecordEvent.fire();
	},
    openAddCustomerModal : function (cmp, evt, hlp) {
        cmp.set("v.AddWaitCustomerButtonClicked", true);
        cmp.set("v.addCustomerOpen", true);
        var cmpTarget = cmp.find('AddCustomerModal');
        var cmpBack = cmp.find('AddCustomerModalBackDrop');
        $A.util.addClass(cmpTarget, 'slds-fade-in-open');
        $A.util.addClass(cmpBack, 'slds-backdrop_open');
    },
    closeAddCustomerModal : function (cmp, evt, hlp) {
        var cmpTarget = cmp.find('AddCustomerModal');
        var cmpBack = cmp.find('AddCustomerModalBackDrop');
        $A.util.removeClass(cmpBack,'slds-backdrop_open');
        $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
        cmp.set("v.addCustomerOpen", false);
        hlp.fireRefreshEvent(cmp);
    },

	editAssignment : function(cmp,evt,hlp){
		var rowNum = evt.currentTarget.getAttribute("data-value");
		var customersCheckedIn = cmp.get("v.CustomersCheckedInList");
		customersCheckedIn[rowNum].editMode = true;
		cmp.set("v.CustomersCheckedInList",customersCheckedIn);
	},

    changeSelectValue : function(cmp,evt,hlp){

        var rowNum = evt.getSource().get("v.name");
        var customersCheckedIn = cmp.get("v.CustomersCheckedInList");

		// nothing needs to be done if this customer has never been assigned an associate
		if (customersCheckedIn[rowNum].walkInDetails.Assigned_User__r == null) {
			return;
		}

        var assignedConsultant = cmp.find("assignedAssociate");
		var selectedUser = assignedConsultant;
		if(Array.isArray(assignedConsultant)){
			for(var i = 0;i<assignedConsultant.length;i++){
				if(assignedConsultant[i].get("v.name") == rowNum){
					selectedUser = assignedConsultant[i];
					break;
				}
			}
		}
		var userId = selectedUser.get("v.value");

		customersCheckedIn[rowNum].walkInDetails.Assigned_User__r.Id = userId;

		cmp.set("v.CustomersCheckedInList",customersCheckedIn);
    },

	saveAssignment : function(cmp,evt,hlp){
		cmp.set("v.reloading",true);
		var rowNum = evt.currentTarget.getAttribute("data-value");
		var assignedConsultant = cmp.find("assignedAssociate");
		var selectedUser = assignedConsultant;
		if(Array.isArray(assignedConsultant)){
			for(var i = 0;i<assignedConsultant.length;i++){
				if(assignedConsultant[i].get("v.name") == rowNum){
					selectedUser = assignedConsultant[i];
					break;
				}
			}
		}
		var userId = selectedUser.get("v.value");
		var customersCheckedIn = cmp.get("v.CustomersCheckedInList");
		var apptId = customersCheckedIn[rowNum].walkInDetails.Appointment_Id__c;
		var walkinId = customersCheckedIn[rowNum].walkInDetails.Id;
		hlp.saveAssignmentHelper(cmp, evt, userId, apptId, walkinId);
	},

	cancelAssignment : function(cmp,evt,hlp){
		hlp.cancelAssignmentHelper(cmp,evt);
	},

    assignAssociate : function (cmp, evt, hlp) {
        cmp.set("v.reloading",true);
        var rowNum = evt.getSource().get("v.value");
        var users = cmp.find('assignedAssociate');
        var selectedUser=users;
        if(Array.isArray(users)){
			for (var i = 0; i < users.length; i++) {
				if (rowNum == users[i].get('v.name')) {
                    selectedUser = users[i];
					break;
				}
			}
        }
		var recordId=cmp.get("v.CustomersCheckedInList")[rowNum].walkInDetails.Id;
        var assocId=selectedUser.get("v.value");
        var apptId=cmp.get("v.CustomersCheckedInList")[rowNum].walkInDetails.Appointment_Id__c;
        if(assocId && recordId){
            var action = cmp.get("c.AssignAssociate");
            action.setParams({
                recordId : recordId,
                associateId : assocId,
                apptId :apptId
            });
            action.setCallback(this, function(response) {
                if(response.getState() === "SUCCESS") {
                    hlp.fireRefreshEvent(cmp);
                }else if(response.getState() === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                            hlp.showErrorMessage(cmp,evt, hlp,"Error message: " + errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                        hlp.showErrorMessage(cmp,evt, hlp,"Unknown error");
                    }
                }else if (!response.getReturnValue().success) {
                    hlp.showErrorMessage(cmp,evt, hlp,response.getReturnValue().errorMessage);
                }
                cmp.set("v.reloading",false);
            });
            $A.enqueueAction(action);
        }
        else{
            if(users.length){
                users[rowNum].set('v.required', true);
                users[rowNum].showHelpMessageIfInvalid();
            } else {
                users.set('v.required', true);
                users.showHelpMessageIfInvalid();
            }
            cmp.set("v.reloading",false);
        }
    },

    confirmAssignAssociate : function (cmp, evt, hlp) {
        cmp.set("v.reloading",true);
        var rowNum = evt.getSource().get("v.value");
		var recordId=cmp.get("v.CustomersCheckedInList")[rowNum].walkInDetails.Id;
        var action = cmp.get("c.ConfirmAssignAssociate");
        action.setParams({
            recordId : recordId
        });
        action.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS") {
                hlp.fireRefreshEvent(cmp);
            }else if(response.getState() === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                        hlp.showErrorMessage(cmp,evt, hlp,"Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                    hlp.showErrorMessage(cmp,evt, hlp,"Unknown error");
                }
            }else if (!response.getReturnValue().success) {
                hlp.showErrorMessage(cmp,evt, hlp,response.getReturnValue().errorMessage);
            }
            cmp.set("v.reloading",false);
        });
        $A.enqueueAction(action);
    },

    showPopOver : function(cmp,evt,hlp){
        var whatElement = evt.currentTarget;
        var rowNum = whatElement.getAttribute("data-rowNum");
        var cmpTarget = cmp.find('custInfoPop');
        var cmpTable = cmp.find('crm_checkInTable');
        if(cmpTarget.length){
            cmpTarget = cmpTarget[rowNum];
        }
        var rect = whatElement.getBoundingClientRect();
        var viewportHeight = window.innerHeight;
        var obj = cmpTarget.getElement();
        var xOffsetNum = rect.left-15;
        var xOffsetStr = xOffsetNum.toString()+"px";
        var yOffsetNum = viewportHeight-(rect.top-15);
        var yOffsetStr = yOffsetNum.toString()+"px";
        obj.style.bottom = yOffsetStr;
        obj.style.left = xOffsetStr;
        obj.style.position = 'fixed';

        $A.util.addClass(cmpTarget, 'slds-show');
        $A.util.removeClass(cmpTarget, 'slds-hide');
    },

    hidePopOver : function(cmp,evt,hlp){
        var whatElement = evt.currentTarget;
        var rowNum = whatElement.getAttribute("data-rowNum");
        var cmpTarget = cmp.find('custInfoPop');
        if(cmpTarget.length){
            cmpTarget = cmpTarget[rowNum];
        }

        $A.util.addClass(cmpTarget, 'slds-hide');
        $A.util.removeClass(cmpTarget, 'slds-show');
    },
    allowDrop : function(cmp,evt,hlp){
        evt.preventDefault();
    },
    dropData : function(cmp,evt,hlp){
        evt.preventDefault();
        var rowNum = evt.currentTarget.getAttribute("data-rowNum");
        var userId = evt.dataTransfer.getData("Text");
        var assignedConsultant = cmp.find("assignedAssociate");
        var selectedUser = assignedConsultant;
        if(Array.isArray(assignedConsultant)){
            for(var i = 0;i<assignedConsultant.length;i++){
                if(assignedConsultant[i].get("v.name") == rowNum){
                    selectedUser = assignedConsultant[i];
                }
            }
        }

        selectedUser.set("v.value",userId);
    },
    openCustomerDetailModal : function (cmp, evt, hlp) {
        let showSaveBtn = true;
        let editable = true;
        var modalHeader;
        var modalBody;
        var modalFooter;
        var rowNum = evt.currentTarget.getAttribute("data-rowNum");
        let custDetails = JSON.parse(JSON.stringify(cmp.get("v.CustomersCheckedInList")[rowNum]));
        let custName = custDetails.walkInDetails.Name__c;
        var overlayLibAppt = cmp.find('overlayLib');
        let isWalkin = false;
        if(custDetails.walkInDetails.Id != null) {
            isWalkin = true;
        }
        $A.createComponents([
            ["c:CRM_modalHeader",{"modalTitle" : custName+"'s Details","modalIcon" : "standard:contact","modalIconAltText" : 'Customer'}],
            ["c:CRM_Point_Checkin_App_CustInfo",{"CurrentUserDetails":cmp.get("v.CurrentUserDetails"),'selectedCustData':custDetails, 'isWalkin': isWalkin,'editable': editable,'glanceableViewEnabled':cmp.get("v.glanceableViewEnabled")}],
            ["c:CRM_modalFooter",{"showCloseBtn" : true,"showSaveBtn" : showSaveBtn,"saveWalkInCustModal":true}]
        ],

            function(components,status){
                if(status==="SUCCESS"){
                    modalHeader = components[0];
                    modalBody = components[1];
                    modalFooter = components[2];
                    overlayLibAppt.showCustomModal({
                        header: modalHeader,
                        body:modalBody,
                        showCloseButton:true,
                        footer: modalFooter,
                        cssClass:"crm_custDetailModal",
                        closeCallback:function(){}
                    })
                }
            }
        );
    },
    openAddCustModal : function (cmp, evt, hlp) {
        var modalHeader;
        var modalBody;
        var modalFooter;
        var overlayLibAppt = cmp.find('overlayLib')
        $A.createComponents([
                ["c:CRM_modalHeader",{"modalTitle" : "Check In Customer","modalIcon" : "action:new_person_account","modalIconAltText" : 'Add Walk In Customer'}],
                ["c:CRM_PointCheckin_AddCustomer",{"CurrentUserDetails":cmp.get("v.CurrentUserDetails"),"UserActiveLocation":cmp.get("v.UserActiveLocation")}],
                ["c:CRM_modalFooter",{"showCancelBtn" : true,"showSaveBtn" : true,"saveWalkInCustModal":true}]
            ],
            function(components,status){
                if(status==="SUCCESS"){
                    cmp.set("v.addCustomerOpen",true);
                    modalHeader = components[0];
                    modalBody = components[1];
                    modalFooter = components[2];
                    overlayLibAppt.showCustomModal({
                        header: modalHeader,
                        body:modalBody,
                        showCloseButton:true,
                        footer: modalFooter,
                        cssClass:"crm_custDetailModal",
                        closeCallback:function(){
                            cmp.set("v.addCustomerOpen",false);
                        }
                    })
                }
            }
        );
    }
})