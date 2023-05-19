({
	init : function(cmp, evt, hlp) {
		var columns = [
			{label:"Appt Time",labelVisible:'true'},
			{label:"Customer",labelVisible:'true'},
			{label:"IO",labelVisible:'true'},
			{label:"EPU",labelVisible:'true'},
			{label:"Associate",labelVisible:'true'},
         //   {label:"ETA",labelVisible:'true'},
			{label:"Arrived",labelVisible:'false'},
			{label:"Cancel",labelVisible:'false'}
		];
		
		if(cmp.get('displayProgressBar')){
			columns.push({label:"Progress",labelVisible:'true'});
		}
		cmp.set('v.columns',columns);
		hlp.getData(cmp,null)
			.then(
				$A.getCallback(function(result){
				}),
				$A.getCallback(function(error){
					console.log(error);
				})
			);
	},

	handleRefreshEvent : function (component, event, helper) {
		var eventLocations = event.getParam('locations');
		var userActiveLocation = component.get("v.CurrentUserDetails").Active_Location__c;

		if (eventLocations.includes(userActiveLocation)) {
			console.log('Refreshing appointments...');
			var initMethod = component.get('c.init');
			$A.enqueueAction(initMethod);
		}
		else {
			console.log('Ignoring refresh event as it is not for the active location');
		}
	},

	showDetails : function(cmp,evt,hlp){
		var whereAmI = evt.target.getBoundingClientRect();
		var whatToPopUp = cmp.find("myPopup");
		var infoElements = cmp.find("infoButton");
		var whereToPopUpTop = whereAmI.top;
		cmp.set("v.popUpBottom",whereToPopUpTop+'px')
		var whatToPopUpAgain = cmp.find("myPopup");
		$A.util.addClass(whatToPopUpAgain, 'slds-show');
		$A.util.removeClass(whatToPopUpAgain, 'slds-hide');
	},

	handleAssign : function(cmp,evt,hlp){
		cmp.set("v.reloading",true);
		var apptId = evt.getSource().get("v.value");
		var assignedConsultant = cmp.find("selectedUser");
		var userId;
		try{
			var dataset = cmp.get("v.data");
			userId = dataset.find(function (x) { return x.apptId == apptId }).assignedId;
		}catch(err){
			console.log('an error has occured in the handleAssign method of the appointmentsJS Controller' + err);
		}
		hlp.assigningAppt(cmp,userId,apptId,false,false);
	},

	handleCheckIn : function(cmp,evt,hlp){
		cmp.set("v.reloading",true);
		var apptId = evt.getSource().get("v.value");
		var assignedConsultant = cmp.find("selectedUser");
		var userId;
		try{
			var dataset = cmp.get("v.data");
			userId = dataset.find(function (x) { return x.apptId == apptId }).assignedId;
		}catch(err){
			console.log('an error has occured in the handleAssign method of the appointmentsJS Controller' + err);
		}
		hlp.assigningAppt(cmp,userId,apptId,false,true);
	},

	markNoShow : function(cmp,evt,hlp){
		cmp.set("v.reloading",true);
		var apptId = evt.getSource().get("v.value");
		var assignedConsultant = cmp.find("selectedUser");
		var selectedUser = assignedConsultant;
		if(Array.isArray(assignedConsultant)){
			for(var i = 0;i<assignedConsultant.length;i++){
				if(assignedConsultant[i].get("v.name") == apptId){
					selectedUser = assignedConsultant[i];
				}
			}
		}
		var userId;
		try{
			userId = selectedUser.get("v.value");
		}catch(err){
			userId = document.getElementById("user"+apptId).getAttribute('data-value');
		}
		// var apptId = document.getElementById("appointmentTime"+rowNum).getAttribute('data-value');
		var dataset = cmp.get("v.data");
		userId = dataset.find(function (x) { return x.apptId == apptId }).assignedId;
		hlp.assigningAppt(cmp,userId,apptId,true);
	},

	editAssignment : function(cmp,evt,hlp){
		var apptId = evt.currentTarget.getAttribute("data-value");
		var data = cmp.get("v.data");
		data.find(function (x) { return x.apptId == apptId }).assignmentEdit = true;
		cmp.set("v.data",data);
	},

	saveAssignment : function(cmp,evt,hlp){
		cmp.set("v.reloading",true);
		var apptId = evt.currentTarget.getAttribute("data-value");
		var assignedConsultant = cmp.find("selectedUser");
		var selectedUser = assignedConsultant;
		if(Array.isArray(assignedConsultant)){
			for(var i = 0;i<assignedConsultant.length;i++){
				if(assignedConsultant[i].get("v.name") == apptId){
					selectedUser = assignedConsultant[i];
				}
			}
		}
		try{
			var dataset = cmp.get("v.data");
			var userId = dataset.find(function (x) { return x.apptId == apptId }).assignedId;
		}catch(err){
			console.log('an error has occured in the saveAssignment method in appointmentsJS Controller '+ err);
		}
		var userStore = cmp.get("v.CurrentUserDetails").Active_Location__c;
		var userRegion = cmp.get("v.CurrentUserDetails").Region__c;
		hlp.assigningUser(cmp,userId,apptId,userStore,userRegion);
		hlp.cancelAssignmentHelper(cmp,evt);
	},

	cancelAssignment : function(cmp,evt,hlp){
		hlp.cancelAssignmentHelper(cmp,evt);
	},

	//May not be used any longer
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

	// May also not be used any longer
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


    changeSelectValue : function(cmp,evt,hlp){
		var whatElement = evt.target;
		var apptId = whatElement.getAttribute("data-apptId");
		var data = cmp.get("v.data");
		var rowNum = data.findIndex(function (x) { return x.apptId == apptId });
		var assignedConsultant = cmp.find("selectedUser");
		var selectedUser = assignedConsultant;
		if(Array.isArray(assignedConsultant)){
			for(var i = 0;i<assignedConsultant.length;i++){
				if(assignedConsultant[i].get("v.name") == apptId){
					selectedUser = assignedConsultant[i];
				}
			}
		}
		var userId = selectedUser.get("v.value");

		if(userId!=data[rowNum].assignedId){
			data[rowNum].isSoftAssigned = (userId=="");
			data[rowNum].assignedId=userId;
		}

		cmp.set("v.data",data);
    },
    allowDrop : function(cmp,evt,hlp){
		evt.preventDefault();
    },
    dropData : function(cmp,evt,hlp){
		var data = cmp.get("v.data");
		evt.preventDefault();
		var apptId = evt.target.getAttribute("data-apptId");
		var userId = evt.dataTransfer.getData("Text");
		var rowNum = data.findIndex(function (x) { return x.apptId == apptId });
		var assignedConsultant = cmp.find("selectedUser");
		var selectedUser = assignedConsultant;
		if(Array.isArray(assignedConsultant)){
			for(var i = 0;i<assignedConsultant.length;i++){
				if(assignedConsultant[i].get("v.name") == apptId){
					selectedUser = assignedConsultant[i];
				}
			}
		}

		var dataset = cmp.get("v.data");
		dataset[rowNum].isSoftAssigned = false;
		dataset[rowNum].assignedId=userId;
		cmp.set("v.data", dataset);
    },
    openCustomerDetailModal : function (cmp, evt, hlp) {
        var modalHeader;
        var modalBody;
        var modalFooter;
		var apptId = evt.currentTarget.getAttribute("data-apptId");
		var data = cmp.get('v.data');
		var rowNum = data.findIndex(function (x) { return x.apptId == apptId });
        var custDetails = data[rowNum].custDetails;
		var custName = data[rowNum].customerName;
		var apptId = data[rowNum].apptId;
		var overlayLibAppt = cmp.find('overlayLib')
        $A.createComponents([
			["c:CRM_modalHeader",{"modalTitle" : custName+"'s Details","modalIcon" : "standard:contact","modalIconAltText" : 'Customer'}],
			["c:CRM_Point_Checkin_App_CustInfo",{'selectedCustData':custDetails, 'apptId': apptId,'glanceableViewEnabled':cmp.get("v.glanceableViewEnabled")}],
			["c:CRM_modalFooter",{"showCloseBtn" : true}]
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
    loadMore : function(cmp,evt,hlp){
		cmp.set("v.reloading",true);
		hlp.getData(cmp,cmp.get("v.aggData"))
			.then(
				$A.getCallback(function(result){
					cmp.set("v.reloading",false);
				}),
				$A.getCallback(function(error){
					cmp.set("v.reloading",false);
					console.log(error);
				})
			);
    }
})