/*
	类名：HighSeasRulePageController
	功能：设置公海池规则页面的控制类。
	作者：Jimmy cao 曹阳
	时间：2018-09-17
    测试类：HighSeasRulePageController_Test
    覆盖率：94.49%
*/
public with sharing class HighSeasRulePageController {
    

    public static MetadataFieldClass getMetadataFieldClass()
    {
        String THEOBJECT = 'Account';
        String OBJECTAPI = 'Account';
        String OBJECTLABEL = '客户';

        SystemParameters__c switcher1 = SystemParameters__c.getValues('OBJECTAPI');
        if(switcher1 != null && switcher1.Value__c != null && switcher1.Value__c != '')
        {
            OBJECTAPI = switcher1.Value__c;
        }
        SystemParameters__c switcher2 = SystemParameters__c.getValues('OBJECTLABEL');
        if(switcher2 != null && switcher2.Value__c != null && switcher2.Value__c != '')
        {
            OBJECTLABEL = switcher2.Value__c;
        }
        SystemParameters__c switcher3 = SystemParameters__c.getValues('THEOBJECT');
        if(switcher3 != null && switcher3.Value__c != null && switcher3.Value__c != '')
        {
            THEOBJECT = switcher3.Value__c;
        }
        return new MetadataFieldClass(THEOBJECT,OBJECTAPI);
    }

    @AuraEnabled
    public static String GetAllRole() {
        String profileId = UserInfo.getProfileId();
        Profile pro = [select id,Name from Profile WHERE Id =: profileId];//当前登录人简档
        //获取自定义设置中配置的允许使用的字段
        map<String,HighSeasField__c> settingfieldMap = HighSeasField__c.getall();

        Map<String,Object> returnObjectMap = new Map<String,Object>();
        returnObjectMap.put('Profile', pro);

        List<HighSeasType__c> highSeasTypes = HighSeasType__c.getall().values();
        returnObjectMap.put('highSeasType', highSeasTypes);


        MetadataFieldClass mf = HighSeasRulePageController.getMetadataFieldClass();

        //调用MetadataFieldClass类的方法，获取到全部字段的列表
        Map<String,String> fieldMap = new Map<String,String>();
        List<SelectOption> fieldsMap = mf.fieldsMap;
        for(SelectOption so : fieldsMap)
        {
            if(settingfieldMap != null && settingfieldMap.containsKey(so.getValue()))
            {
                fieldMap.put(so.getValue(), so.getLabel());
            }
            else if(settingfieldMap == null)
            {
                fieldMap.put(so.getValue(), so.getLabel());
            }

        }
        returnObjectMap.put('fieldMap',fieldMap);

        //调用MetadataFieldClass类的方法，获取到全部运算符
        Map<String,String> operatorMap = new Map<String,String>();
        List<SelectOption> operatorList = mf.operatorList;
        for(SelectOption so : operatorList)
        {
            operatorMap.put(so.getValue(), so.getLabel());
        }
        returnObjectMap.put('operatorMap',operatorMap);

        //调用MetadataFieldClass类的方法，获取选填筛选条件的列表
        List<MetadataFieldClass.Conditions> conditionList = new List<MetadataFieldClass.Conditions>();
        for(Integer index=0;index<5;index++)
        {
            mf.AddCondition(conditionList);//调用工具类中添加筛选条件行数的方法。
        }
        returnObjectMap.put('conditionList',conditionList);
        return JSON.serializePretty(returnObjectMap);
    }

    @AuraEnabled
    public static String SaveRule(String conditionsJson,String logic,String highSeasType,String returnReason,String noticeAddress)
    {
        System.debug('=====conditionsJson:'+conditionsJson);
        System.debug('=====logic:'+logic);
        String SaveResult = 'FALSE';
        if(logic != null)
        {
            logic = logic.toLowerCase();
            logic = logic.replace(' ','').replace('and',' and ').replace('or',' or ').replace('(',' ( ').replace(')',' ) ');
        }
        List<MetadataFieldClass.Conditions> conditionList = (List<MetadataFieldClass.Conditions>) JSON.deserializeStrict(conditionsJson, List<MetadataFieldClass.Conditions>.class);
        //调用拼接SQL的方法，返回值为拼接好的SQL语句。
        MetadataFieldClass mf = HighSeasRulePageController.getMetadataFieldClass();
        String returnResult = mf.CheckConditions(conditionList,logic);
        System.debug('========returnResult:'+returnResult);
        returnResult = returnResult.split('where')[0] + ' where RecordType.Name = \'学员\' and HighSeasData__c = false and ' + returnResult.split('where')[1];
        System.debug('========returnResult:'+returnResult);
        List<AggregateResult> arList = new List<AggregateResult>();
        try{
            arList = Database.query(returnResult+' Limit 10');
            High_Seas_Rule__c rule = new High_Seas_Rule__c();
            rule.DataQuery_SQL__c = returnResult; //sql语句
            rule.Condition_Logic__c = logic; //条件并列关系
            rule.Data_Filter_Condition__c = ''; //条件
            rule.Department_Name__c = highSeasType;//所属公海
            rule.ReturnReason__c = returnReason; //退回原因
            rule.NoticeAddress__c = noticeAddress;//退回数据的邮件通知地址
            for(MetadataFieldClass.Conditions con : conditionList)
            {
                rule.Data_Filter_Condition__c = rule.Data_Filter_Condition__c + con.num + '、' + con.fieldsLabel + ' ' + mf.operMap.get(con.operator) + ' ' + con.fieldsValue + ';\n';
            }
            INSERT rule;
            SaveResult = 'SUCCESS';
        }
        catch(Exception e)
        {
            SaveResult = '筛选条件错误,请检查筛选条件！';
        }
        return SaveResult;
    }

    @AuraEnabled
    public static String SeachDataList(String conditionsJson,String logic)
    {
        System.debug('=====conditionsJson:'+conditionsJson);
        System.debug('=====logic:'+logic);
        if(logic != null)
        {
            logic = logic.toLowerCase();
            logic = logic.replace(' ','').replace('and',' and ').replace('or',' or ').replace('(',' ( ').replace(')',' ) ');
        }
        List<MetadataFieldClass.Conditions> conditionList = (List<MetadataFieldClass.Conditions>) JSON.deserializeStrict(conditionsJson, List<MetadataFieldClass.Conditions>.class);
        //调用拼接SQL的方法，返回值为拼接好的SQL语句。
        MetadataFieldClass mf = HighSeasRulePageController.getMetadataFieldClass();
        String returnResult = mf.CheckConditions(conditionList,logic);
        System.debug('========returnResult:'+returnResult);
        returnResult = returnResult.split('where')[0] + ' where RecordType.Name = \'学员\' and HighSeasData__c = false and ' + returnResult.split('where')[1];        List<AggregateResult> arList = new List<AggregateResult>();
        System.debug('========returnResult:'+returnResult);
        try{
            List<InnerAccount> accountList = new List<InnerAccount>();
            Set<String> accIds = new Set<String>();
            arList = Database.query(returnResult+' Limit 500');
            for(AggregateResult ar : arList)
            {
                accIds.add((String)ar.get('dataId'));
            }
            System.debug('=====accIds:'+accIds.size());
            /*******增加通过记录ID查询审批步骤表的逻辑，用来判断出不在审批流程中的数据******/
            List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId,ProcessInstance.TargetObjectId 
                                                          FROM ProcessInstanceWorkitem 
                                                          WHERE ProcessInstance.TargetObjectId IN: accIds];
            //当存在批准流程时，说明当前这条数据是未审批结束的，从ID集合中将这条数据的ID Remove掉。
            for(ProcessInstanceWorkitem workItem : workItems)
            {
                if(accIds.contains(workItem.ProcessInstance.TargetObjectId))
                {
                    accIds.remove(workItem.ProcessInstance.TargetObjectId);
                }
            }

            for(Account acc : [SELECT Id,Name FROM Account WHERE Id IN: accIds])
            {
                InnerAccount iAccount = new InnerAccount();
                iAccount.isChecked = FALSE;
                iAccount.accountData = acc;
                accountList.add(iAccount);
            }
            System.debug('=====accountList:'+accountList.size());
            return JSON.serializePretty(accountList);
        }
        catch(Exception e)
        {
            return 'ERROR';
        }
    }

    @AuraEnabled
    public static String GetFiledType(String conditionsJson)
    {
        System.debug('======conditionsJson:'+conditionsJson);
        MetadataFieldClass mf = HighSeasRulePageController.getMetadataFieldClass();
        List<MetadataFieldClass.Conditions> conditionList = (List<MetadataFieldClass.Conditions>) JSON.deserializeStrict(conditionsJson, List<MetadataFieldClass.Conditions>.class);
        for(MetadataFieldClass.Conditions con : conditionList)
        {
            mf.GetPickListValueDo(con.fieldsName,conditionList,''+con.num);
        }
        return JSON.serializePretty(conditionList);
    }

    @AuraEnabled
    public static String ReturnToHighSeas(String accountsJson,String highSeasType,String returnReason,String noticeAddress)
    {
        try
        {
            Set<String> accountIds = new Set<String>();
            SystemParameters__c highSeasOwner = SystemParameters__c.getValues('HighSeasOwner'); //退回公海池的数据所有人
            List<User> userList = null;
            if(highSeasOwner != null)
            {
                userList = new List<User>([SELECT id,userName FROM User WHERE userName =: highSeasOwner.Value__c]);
            }
            List<Account> returnAccountList = new List<Account>();
            List<InnerAccount> accountList = (List<InnerAccount>) JSON.deserializeStrict(accountsJson, List<InnerAccount>.class);
            for(InnerAccount con : accountList)
            {
                Account acc = new Account();
                acc.Id = con.accountData.Id;
                accountIds.add(acc.Id);
                if(returnReason != null)
                {
                    acc.BackReason__c = returnReason;
                }
                else
                {
                    acc.BackReason__c = '管理员批量退回';
                }
                if(userList != null && userList.size() > 0)
                {
                    acc.OwnerId = userList[0].Id;
                }
                else
                {
                    acc.OwnerId = UserInfo.getUserId();
                }
                acc.Refund_Date__c = System.now();
                acc.AccountPoolStyle__c = highSeasType;
                acc.HighSeasData__c = true;
                returnAccountList.add(acc);
            }
            UPDATE returnAccountList;
            if (noticeAddress != '123456789')
            {
                SendEmail(accountIds,noticeAddress);
            }
            return 'SUCCESS';
        }
        catch(Exception e)
        {
            return e.getMessage();
        }
    }


    public static void SendEmail(Set<String> accountIds,String emailAddresses)
    {
        if(accountIds != null && accountIds.size() > 0 && String.isNotBlank(emailAddresses))
        {
            List<Account> oplist = [SELECT Id,Name,Phone,Wechat__c,Email__c FROM Account WHERE Id IN: accountIds];
            String Title='<html>'+
                        '<form>'+
                        '<body>'+
                        '<table  >'+
                        '您好<br/>&nbsp;&nbsp;&nbsp;'+
                        '&nbsp;&nbsp;&nbsp;&nbsp;以下客户已被回收至公海池，请知悉。<br/>'+
                        '<table border="1" style="border-collapse:collapse;text-align:center;width:800px;" id="table">'+
                            '<tr>'+
                                '<td style="background-color: #4876FF;width:8%"><p style="color: white">姓名</p></td>'+
                                '<td style="background-color: #4876FF;width:8%"><p style="color: white">电话</p></td>'+
                                '<td style="background-color: #4876FF;width:8%"><p style="color: white">微信ID</p></td>'+
                                '<td style="background-color: #4876FF;width:8%"><p style="color: white">邮件</p></td>'+
                            '</tr>';
                        String  foot='</table>'+
                        '<br/>祝你工作愉快！<br/>'+
                        '____________________________________________'+
                        '<br/>'+
                        '本邮件由CRM系统产生，请勿回复！。<br/>'+
                        '如有任何疑问或者建议，请联系系统管理员。'+
                        '</table>'+
                        '</body>'+
                        '</form>'+
                        '</html>';

                        String finalbody =Title;
                        String body;
                        for(Account  le :oplist)
                        {
                            body += '<tr> '+
                                          '<td>'+le.Name+'</td>'+
                                          '<td>'+le.Phone+'</td>'+
                                          '<td>'+le.Wechat__c+'</td>'+
                                          '<td>'+le.Email__c+'</td>'+
                                    '</tr>';
                        }
                        finalbody += body + foot;
                        finalbody =  finalbody.replace('00:00:00', '');
                        finalbody = finalbody.replace('null', '');
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        String[] toAddresses = emailAddresses.replace('，', ',').split(',');
                        mail.setSaveAsActivity(false);
                        mail.setToAddresses(toAddresses);       
                        mail.setSenderDisplayName('CRM系统通知');
                        mail.setSubject('邮件分配提醒！！');
                        mail.setHtmlBody(finalbody);
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        }
    }

    public class InnerAccount
    {
        public boolean isChecked{get;set;}
        public Account accountData{get;set;}
    }
}