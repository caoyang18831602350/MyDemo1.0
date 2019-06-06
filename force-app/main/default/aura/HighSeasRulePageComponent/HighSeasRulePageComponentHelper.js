({
    doInithelper : function(cmp) 
    {
    	//这里的c.代表调用服务器端方法
    	var action = cmp.get("c.GetAllRole");
        //调用回掉函数
        action.setCallback(this, function(response)
        {
            //定义提示信息
            var toastEvent = $A.get("e.force:showToast");
            var state = response.getState();
            //判断后台返回状态
            if(state == "SUCCESS")
            {
            	var uRoleArray = new Array()
            	//获取后台返回的参数
                var result = response.getReturnValue();
                var obj = JSON.parse(result); 


                //字段集合
                var fieldMap = [];
                for(var key in obj.fieldMap){
                    fieldMap.push({value:obj.fieldMap[key], key:key});
                }

                //运算符集合
                var operatorMap = [];
                for(var key in obj.operatorMap){
                    operatorMap.push({value:obj.operatorMap[key], key:key});
                }

                var highSeasTypes = new Array();
                //公海池集合
                for (var i = 0; i < obj.highSeasType.length; i++) {
                    var highSeasType = new Object();
                    highSeasType.value = obj.highSeasType[i].Name;
                    highSeasType.label = obj.highSeasType[i].Name;
                    highSeasTypes[i] = highSeasType;
                }

                cmp.set("v.fieldMap", fieldMap); //字段集合
                cmp.set("v.operatorMap", operatorMap); //运算符集合
                cmp.set("v.conditionList", obj.conditionList); //筛选条件列表
                console.log("===Profile:",obj.Profile);
                cmp.set("v.ProfileName", obj.Profile.Name); //筛选条件列表
                cmp.set("v.highSeasType", highSeasTypes); //筛选条件列表
            }
            else
            {
                //设置错误提示信息 
                toastEvent.setParams(
                {
                    "title" : "初始化数据",
                    "message" : "数据初始化失败，请重试！Error:"+response.getError(),
                    "type" : "Error"
                });
            }
            //将提示信息发出 如果不写这句话 将不会有提示信息 这个事件是系统自带事件，Lightning框架会监听这个事件
            toastEvent.fire();
            //将Loading图标取消
            var spinner = cmp.find("mySpinner");
            $A.util.toggleClass(spinner,"slds-hide");
        });
        //从客户端控制器调用服务器端控制器操作
        $A.enqueueAction(action);
    },
    FieldChangehelper : function(cmp,event)
    {
        var conditionList = cmp.get("v.conditionList");

        //加载Loading遮罩层
        var spinner = cmp.find("mySpinner");
        $A.util.toggleClass(spinner,"slds-hide");

        //调用后台方法获取字段类型
        var action = cmp.get("c.GetFiledType");
        action.setParams({
            'conditionsJson': JSON.stringify(conditionList)
        });
        //调用回掉函数
        action.setCallback(this, function(response)
        {
            //定义提示信息
            var toastEvent = $A.get("e.force:showToast");
            var state = response.getState();
            //判断后台返回状态
            if(state == "SUCCESS")
            {
                var conditionList = JSON.parse(response.getReturnValue()); 
                console.log('=====conditionList:',conditionList);
                cmp.set("v.conditionList", conditionList); //筛选条件列表
            }
            else
            {
                //设置错误提示信息 
                toastEvent.setParams(
                {
                    "title" : "错误",
                    "message" : "获取字段类型失败！Error:"+response.getError(),
                    "type" : "Error"
                });
            }
            //将提示信息发出 如果不写这句话 将不会有提示信息 这个事件是系统自带事件，Lightning框架会监听这个事件
            toastEvent.fire();
            //将Loading图标取消
            var spinner = cmp.find("mySpinner");
            $A.util.toggleClass(spinner,"slds-hide");
        });
        //从客户端控制器调用服务器端控制器操作
        $A.enqueueAction(action);
    },
    AddLinehelper : function(cmp,event)
    {
        var conditionList = cmp.get("v.conditionList");
        //创建一个空的数据插入到list当中
        var condition = new Object();
        condition.checkbox = false;
        condition.fieldsLabel = null;
        condition.fieldsName = null;
        condition.fieldsType = null;
        condition.fieldsValue = null;
        condition.labels = null;
        condition.num = conditionList.length + 1;
        condition.operator = null;
        condition.selectOp = null;

        conditionList.push(condition);
        cmp.set("v.conditionList", conditionList);
    },
    DelLinehelper : function(cmp,event)
    {
        //删除被选中的条件
        var conditionList = cmp.get("v.conditionList");
        var removeIndex = null;
        for(var i = conditionList.length-1; i >=0; i--) 
        {
            if(conditionList[i].checkbox)
            {
                conditionList.splice(i, 1);
            }
        }

        //为数组中的数据重新排序号
        for(var i = 0; i < conditionList.length; i++) 
        {
            conditionList[i].num = i + 1;
        }
        cmp.set("v.conditionList", conditionList);
    },
    CheckLegitimate : function(cmp,event,doWhat)
    {
        //定义提示信息
        var toastEvent = $A.get("e.force:showToast");
        var conditionList = cmp.get("v.conditionList");
        var errorStr = null;
        var conditions = new Array();
        var logic = cmp.get("v.logic");
        if(logic != null)
        {
            logic = logic.toLowerCase();
            logic = " "+logic.replace(" ","").replace("and"," and ").replace("or"," or ").replace("("," ( ").replace(")"," ) ")+" ";
            console.log("====logic:",logic);
        }
        for(var i = 0; i < conditionList.length; i++) 
        {
            if(conditionList[i].fieldsName != null && conditionList[i].operator == null)
            {
                errorStr = "筛选条件不正确，运算符不能为空！";
            }
            else if(conditionList[i].fieldsName != null && conditionList[i].operator != null)
            {
                
                if(logic == null || logic.replace(/\s+/g,"") == "" || logic.search(" "+conditionList[i].num+" ") != -1 )
                {
                    conditions[conditions.length] = conditionList[i];
                }
                else
                {
                    errorStr = "筛选逻辑匹配条件错误！";
                }
            }
        }
        if(errorStr == null)
        {
            if(doWhat == "save")
            {
                this.DoSaveRulehelper(cmp,event,conditions);
            }
            else if(doWhat == "seach")
            {
                this.SeachDatahelper(cmp,event,conditions);
            }
        }
        else
        {
            //设置错误提示信息 
            toastEvent.setParams(
            {
                "title" : "错误！",
                "message" : errorStr,
                "type" : "Error"
            });
            toastEvent.fire();
        }
    },
    SeachDatahelper : function(cmp,event,conditions)
    {
        //加载Loading图标
        var spinner = cmp.find("mySpinner");
        $A.util.toggleClass(spinner,"slds-hide");
        //这里的c.代表调用服务器端方法
        var action = cmp.get("c.SeachDataList");
        action.setParams({
            'logic': cmp.get("v.logic"),
            'conditionsJson': JSON.stringify(conditions),
        });
        
        //调用回掉函数
        action.setCallback(this, function(response)
        {
            //定义提示信息
            var toastEvent = $A.get("e.force:showToast");
            var state = response.getState();
            //判断后台返回状态
            if(state == "SUCCESS")
            {
                var result = response.getReturnValue();
                if(result != "ERROR")
                {
                    console.log('Response Time: '+((new Date().getTime())-requestInitiatedTime));
                    var accountList = JSON.parse(response.getReturnValue()); 
                    console.log(accountList);
                    var pageSize = cmp.get("v.pageSize");
                    cmp.set('v.acccountList', accountList);
                    cmp.set("v.totalSize", cmp.get("v.acccountList").length);
                    cmp.set("v.start",1);
                    cmp.set("v.end",pageSize);
                    var paginationList = new Array();
                    if(accountList.length < pageSize)
                    {
                        pageSize = accountList.length;
                    }
                    for(var i=0; i< pageSize; i++)
                    {
                        paginationList.push(accountList[i]);    
                    }
                    cmp.set('v.paginationList', paginationList);
                }
                else
                {
                    //设置错误提示信息 
                    toastEvent.setParams(
                    {
                        "title" : "查询失败",
                        "message" : "查询失败，筛选条件不正确！",
                        "type" : "Error"
                    });
                }
            }
            else
            {
                //设置错误提示信息 
                toastEvent.setParams(
                {
                    "title" : "保存失败",
                    "message" : "保存筛选条件失败，请重试！Error:"+response.getError(),
                    "type" : "Error"
                });
            }
            //将提示信息发出 如果不写这句话 将不会有提示信息 这个事件是系统自带事件，Lightning框架会监听这个事件
            toastEvent.fire();
            //将Loading图标取消
            var spinner = cmp.find("mySpinner");
            $A.util.toggleClass(spinner,"slds-hide");
        });
        var requestInitiatedTime = new Date().getTime();
        //从客户端控制器调用服务器端控制器操作
        $A.enqueueAction(action);
    },
    DoSaveRulehelper : function(cmp,event,conditions)
    {
        var highSeasRuleName = cmp.find("highSeasRuleName").get("v.value");
        var returnReason = cmp.find("ReturnReason").get("v.value");
        var noticeAddress = cmp.find("noticeAddress").get("v.value");
        console.log("===========highSeasRuleName:",highSeasRuleName);
        console.log("===========returnReason:",returnReason);
        console.log("===========noticeAddress:",noticeAddress);
        var toastEvent = $A.get("e.force:showToast");
        if(highSeasRuleName == null || highSeasRuleName == "")
        {
            //设置错误提示信息 
            toastEvent.setParams(
            {
                "title" : "错误",
                "message" : "公海池不能为空！",
                "type" : "Error"
            });
            toastEvent.fire();
        }
        else if(returnReason == null || returnReason == "")
        {
            //设置错误提示信息 
            toastEvent.setParams(
            {
                "title" : "错误",
                "message" : "退回公海池原因不能为空！",
                "type" : "Error"
            });
            toastEvent.fire();
        }
        else if(noticeAddress == null || noticeAddress == "")
        {
            //设置错误提示信息 
            toastEvent.setParams(
            {
                "title" : "错误",
                "message" : "邮件通知地址不能为空！",
                "type" : "Error"
            });
            toastEvent.fire();
        }
        else
        {
            //加载Loading图标
            var spinner = cmp.find("mySpinner");
            $A.util.toggleClass(spinner,"slds-hide");
            //这里的c.代表调用服务器端方法
            var action = cmp.get("c.SaveRule");
            action.setParams({
                'logic': cmp.get("v.logic"),
                'conditionsJson': JSON.stringify(conditions),
                'highSeasType' : highSeasRuleName,
                'returnReason' : returnReason,
                'noticeAddress' : noticeAddress
            });
            
            //调用回掉函数
            action.setCallback(this, function(response)
            {
                //定义提示信息
                var state = response.getState();
                //判断后台返回状态
                if(state == "SUCCESS")
                {
                    var result = response.getReturnValue();
                    if(result == "SUCCESS")
                    {
                        //设置错误提示信息 
                        toastEvent.setParams(
                        {
                            "title" : "保存成功",
                            "message" : "筛选条件保存成功！",
                            "type" : "Success"
                        });
                    }
                    else
                    {
                        //设置错误提示信息 
                        toastEvent.setParams(
                        {
                            "title" : "保存失败",
                            "message" : "保存筛选条件失败，错误消息："+result,
                            "type" : "Error"
                        });
                    }
                }
                else
                {
                    //设置错误提示信息 
                    toastEvent.setParams(
                    {
                        "title" : "保存失败",
                        "message" : "保存筛选条件失败，请重试！Error:"+response.getError(),
                        "type" : "Error"
                    });
                }
                //将提示信息发出 如果不写这句话 将不会有提示信息 这个事件是系统自带事件，Lightning框架会监听这个事件
                toastEvent.fire();
                //将Loading图标取消
                var spinner = cmp.find("mySpinner");
                $A.util.toggleClass(spinner,"slds-hide");
            });
            //从客户端控制器调用服务器端控制器操作
            $A.enqueueAction(action);
        }
    },
    ToHighSeashelper : function(cmp,event)
    {
        var highSeasRuleName = cmp.find("highSeasRuleName").get("v.value");
        var returnReason = cmp.find("ReturnReason").get("v.value");
        var noticeAddress = cmp.find("noticeAddress").get("v.value");
        console.log("===========highSeasRuleName:",highSeasRuleName);
        console.log("===========returnReason:",returnReason);
        console.log("===========noticeAddress:",noticeAddress);
        var toastEvent = $A.get("e.force:showToast");
        if(highSeasRuleName == null || highSeasRuleName == "")
        {
            //设置错误提示信息 
            toastEvent.setParams(
            {
                "title" : "错误",
                "message" : "公海池不能为空！",
                "type" : "Error"
            });
            toastEvent.fire();
        }
        else if(returnReason == null || returnReason == "")
        {
            //设置错误提示信息 
            toastEvent.setParams(
            {
                "title" : "错误",
                "message" : "退回公海池原因不能为空！",
                "type" : "Error"
            });
            toastEvent.fire();
        }
        else if(noticeAddress == null || noticeAddress == "")
        {
            //设置错误提示信息 
            toastEvent.setParams(
            {
                "title" : "错误",
                "message" : "邮件通知地址不能为空！",
                "type" : "Error"
            });
            toastEvent.fire();
        }
        else
        {
            var paginationList = cmp.get("v.paginationList");
            var toHighSeasList = cmp.get("v.checkedList");

            if(toHighSeasList.length > 0)
            {
                var spinner = cmp.find("mySpinner");
                $A.util.toggleClass(spinner,"slds-hide");

                var action = cmp.get("c.ReturnToHighSeas");
                action.setParams({
                    'accountsJson': JSON.stringify(toHighSeasList),
                    'highSeasType' : highSeasRuleName,
                    'returnReason' : returnReason,
                    'noticeAddress' : noticeAddress
                });
                
                //调用回掉函数
                action.setCallback(this, function(response)
                {
                    //定义提示信息
                    var state = response.getState();
                    //判断后台返回状态
                    if(state == "SUCCESS")
                    {
                        var result = response.getReturnValue();
                        if(result == "SUCCESS")
                        {
                            //设置错误提示信息 
                            toastEvent.setParams(
                            {
                                "title" : "退回成功",
                                "message" : "退回公海池成功！",
                                "type" : "Success"
                            });
                            toHighSeasList.length = 0;
                            cmp.set("v.checkedList",toHighSeasList);
                            this.CheckLegitimate(cmp,event,"seach");
                        }
                        else
                        {
                            //设置错误提示信息 
                            toastEvent.setParams(
                            {
                                "title" : "退回失败",
                                "message" : "回公海池失败，请重试！Error:"+result,
                                "type" : "Error"
                            });
                        }
                    }
                    else
                    {
                        //设置错误提示信息 
                        toastEvent.setParams(
                        {
                            "title" : "退回失败",
                            "message" : "退回公海池失败，请重试！Error:"+response.getError(),
                            "type" : "Error"
                        });
                    }
                    //将提示信息发出 如果不写这句话 将不会有提示信息 这个事件是系统自带事件，Lightning框架会监听这个事件
                    toastEvent.fire();
                    //将Loading图标取消
                    var spinner = cmp.find("mySpinner");
                    $A.util.toggleClass(spinner,"slds-hide");
                });
                //从客户端控制器调用服务器端控制器操作
                $A.enqueueAction(action);
            }
            else
            {
                //设置错误提示信息 
                toastEvent.setParams(
                {
                    "title" : "退回失败",
                    "message" : "退回操作失败，未选择退回客户！",
                    "type" : "Error"
                });
                toastEvent.fire();
            }
        }
    },
    SelectOptionHelper : function(cmp,label,isCheck,num)
    {
        var selectedKey='';
        var selectedValue='';
        var conditionList = cmp.get('v.conditionList');        
        var count=0;
        var condition = conditionList[parseInt(num)-1];
        for(var i=0;i<condition.selectOp.length;i++)
        { 
            if(condition.selectOp[i].key==label) 
            { 
                if(isCheck=='true')
                { 
                    condition.selectOp[i].isChecked = false; 
                }
                else
                {
                    condition.selectOp[i].isChecked = true; 
                }
            }
            if(condition.selectOp[i].isChecked)
            {
                if(selectedKey != '')
                {
                    selectedKey = selectedKey +","+condition.selectOp[i].key;
                }
                else
                {
                    selectedKey = condition.selectOp[i].key;
                }

                if(selectedValue != '')
                {
                    selectedValue = selectedValue +","+condition.selectOp[i].value;
                }
                else
                {
                    selectedValue = condition.selectOp[i].value;
                }
            }
        }
        condition.fieldsValue = selectedKey;
        condition.fieldsValueLabel = selectedValue;
        conditionList[parseInt(num)-1] = condition;
        cmp.set('v.conditionList',conditionList);        
    }
})