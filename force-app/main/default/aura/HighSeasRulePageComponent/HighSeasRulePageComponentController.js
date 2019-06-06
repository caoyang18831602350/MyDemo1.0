({
    //页面初始化的时候调用此方法
    doInit : function(component, event, helper) {
        var device = $A.get("$Browser.formFactor");
        console.log("====device:",device);
    	// $A.util.toggleClass 是一个开关,开是加上,关是移除
        $A.util.toggleClass(component.find("comfirmDialog"), "slds-fade-in-open");
        $A.util.toggleClass(component.find("comfirmDialogBackdrop"), "slds-backdrop--open");
    	helper.doInithelper(component);
    },
    OnFieldChange : function(component, event, helper)
    {
        helper.FieldChangehelper(component,event);
    },
    AddLine : function(component, event, helper)
    {
        helper.AddLinehelper(component,event);
    },
    DelLine : function(component, event, helper)
    {
        helper.DelLinehelper(component,event);
    },
    DoSaveRule : function(component, event, helper)
    {
        helper.CheckLegitimate(component,event,"save");
    },
    SeachData : function(component, event, helper)
    {
        helper.CheckLegitimate(component,event,"seach");
    },
    ToHighSeas : function(component, event, helper)
    {
        helper.ToHighSeashelper(component,event);
    },
    SelectAll : function(component, event, helper)
    {
        var conditionList = component.get("v.conditionList");
        if(conditionList.length > 0)
        {
            var wichButton = event.getSource().getLocalId();
            //获取触发事件复选框的值
            var selectedHeaderCheck = event.getSource().get("v.value");
            var getAllId = null;
            if(wichButton == "productAllbox")
            {
                getAllId = component.find("productbox");
            }
            else
            {
                getAllId = component.find("accountbox");
            }
            if(getAllId != null && !Array.isArray(getAllId))
            {
                getAllId.set("v.value", selectedHeaderCheck);
            }
            else if(getAllId != null)
            {
                for(var i = 0; i < getAllId.length; i++) 
                {
                    getAllId[i].set("v.value", selectedHeaderCheck);
                }
            }
        }
    },
    next : function(component, event, helper) 
    {
        var accountList = component.get("v.acccountList");
        var end = component.get("v.end");//当前页最后一个数据的下标
        var start = component.get("v.start");//当前页第一个数据的小标
        var pageSize = component.get("v.pageSize");//当前页的长度
        var paginationList = [];
        var counter = 0;
        var number = 0;
        if(end+pageSize > accountList.length)
        {
            number = accountList.length;
        }
        else
        {
            number = end+pageSize;
        }
        for(var i=end; i<number; i++)
        {
            if(accountList.length > end)
            {
                paginationList.push(accountList[i]);
                counter ++ ;
            }
        }
        start = end + 1;
        end = end + counter;
        component.set("v.start",start);
        component.set("v.end",end);
        component.set('v.paginationList', paginationList);
    },
    previous : function(component, event, helper) 
    {
        var accountList = component.get("v.acccountList");
        var end = component.get("v.end");
        var start = component.get("v.start");
        var pageSize = component.get("v.pageSize");
        var paginationList = [];

        var counter = 0;
        for(var i= start-pageSize; i < start ; i++)
        {
            if(i > 0)
            {
                paginationList.push(accountList[i-1]);
                counter ++;
            }
            else
            {
                start++;
            }
        }
        end = start - 1;
        start = start - counter;
        component.set("v.start",start);
        component.set("v.end",end);
        component.set('v.paginationList', paginationList);
    },
    OpenDropdown:function(component,event,helper){
        var inputDiv = event.currentTarget;
        $A.util.addClass(inputDiv,'slds-is-open');
        $A.util.removeClass(inputDiv,'slds-is-close');
    },
    CloseDropDown:function(component,event,helper){
        var inputDiv = event.currentTarget;        
        $A.util.addClass(inputDiv,'slds-is-close');
        $A.util.removeClass(inputDiv,'slds-is-open');
    },
    SelectOption:function(component,event,helper){
        var label = event.currentTarget.id.split("#BP#")[0];
        var isCheck = event.currentTarget.id.split("#BP#")[1];
        var num = event.currentTarget.id.split("#BP#")[2];
        helper.SelectOptionHelper(component,label,isCheck,num);
    },
    AddReturnData:function(component,event,helper){
        var toastEvent = $A.get("e.force:showToast");
        var accountId = event.getSource().get("v.value");
        var checkedList = component.get("v.checkedList");
        var accountList = component.get("v.acccountList");
        var isRepeat = false;
        for(var i=0;i<checkedList.length;i++)
        {
            if(checkedList[i].accountData.Id == accountId)
            {
                isRepeat = true;
            }
        }
        if(isRepeat)
        {
            toastEvent.setParams(
            {
                "title" : "错误",
                "message" : "存在相同数据，请勿重复添加！",
                "type" : "Error"
            });
            toastEvent.fire();
        }
        else
        {
            for(var i=0;i<accountList.length;i++)
            {
                if(accountList[i].accountData.Id == accountId)
                {
                    accountList[i].isChecked = true;
                    checkedList[checkedList.length] = accountList[i];
                }
            }
            component.set("v.checkedList", checkedList);
        }
    },
    RemoveReturnData:function(component,event,helper){
        var accountId = event.getSource().get("v.value");
        var checkedList = component.get("v.checkedList");
        for(var i=0;i<checkedList.length;i++)
        {
            if(checkedList[i].accountData.Id == accountId)
            {
                checkedList[i].isChecked = false;
                checkedList.splice(i,1);
            }
        }
        component.set("v.checkedList", checkedList);
    },
    ClearReturnData:function(component,event,helper){
        var checkedList = component.get("v.checkedList");
        checkedList.length = 0;
        component.set("v.checkedList", checkedList);
    },
    CheckedAllShowData:function(component,event,helper){
        var paginationList = component.get("v.paginationList");
        var checkedList = component.get("v.checkedList");
        var dataId = new Array();
        for(var j=0;j<checkedList.length;j++)
        {
            dataId[dataId.length] = checkedList[j].accountData.Id;
        }
        for (var i = 0; i < paginationList.length; i++) {
            if(dataId.indexOf(paginationList[i].accountData.Id) < 0)
            {
                checkedList[checkedList.length] = paginationList[i];
            }
        }
        component.set("v.checkedList", checkedList);
    },
})