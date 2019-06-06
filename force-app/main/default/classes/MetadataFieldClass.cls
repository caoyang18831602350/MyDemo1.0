/*
    类名：MetadataFieldClass
    功能：批量操作数据页面中使用的公用方法的类。
    作者：Jimmy cao 曹阳
    时间：2018-04-16
*/
public without sharing class MetadataFieldClass {
    public String theObject{get;set;}//操作的数据的对象API
    public String objectApi{get;set;}//筛选条件包含的对象API
    public String mainObject{get;set;}//主对象
    public String auxiliaryObject{get;set;}//主对象查找字段的api
    public map<String,String> operMap{get;set;}//运算符Map
    public List<SelectOption> operatorList{get;set;}//运算符的SelectOptionList
    public Map<String, Schema.SObjectField> fieldMap{get;set;}//主对象的字段Map
    public Map<String, Schema.SObjectField> fieldMap2{get;set;}//辅助对象的字段Map
    public String mainObjectLabel{get;set;} //主对象label
    public String auxiObjectLabel{get;set;} //次对象label
    public Map<String,String> fieldLableMap{get;set;}//map<字段的API，字段的Label>
    public List<SelectOption> fieldsMap{get;set;} //最终展示在页面上的字段集合

    public MetadataFieldClass()
    {}

    public MetadataFieldClass(String theObject,String objectApi)
    {
        this.theObject = theObject;
        this.objectApi = objectApi;
        CreateOperator();
        fieldsMap = FieldsMap();
    }

    //增加一行筛选条件
    public void AddCondition(List<Conditions> conditionsList)
    {
        Conditions cond = new Conditions();
        cond.num = conditionsList.size() + 1;
        conditionsList.add(cond);
    }

    //删除指定的筛选条件，删除后，对筛选条件的序号重新进行排序
    public void DelConditions(List<Conditions> conditionsList)
    {
        for(integer i = conditionsList.size()-1;i>=0;i--)
        {
            if(null != conditionsList && null != conditionsList.get(i)){
                if(null != conditionsList.get(i).checkbox && conditionsList.get(i).checkbox)
                {
                    conditionsList.remove(i);
                }
            }
        }
        
        Integer condNum = 1;
        for(Conditions cond : conditionsList)
        {
            cond.num = condNum;
            condNum += 1;
        }
    }
    
    public String CheckConditions(List<Conditions> conditionList,String logic,String userIds)
    {
        userIds = userIds.replace(',', '\',\'');
        if(logic == null || logic == '')
        {
            for(Conditions con : conditionList)
            {
                System.debug('================con:'+con);
                if(con.fieldsName != null && con.fieldsName != '')
                {
                    if(logic == null || logic == '')
                    {
                        logic = ''+con.num;
                    }
                    else
                    {
                        logic = logic + ' and ' + con.num;
                    }
                }
                else
                {
                    continue;
                }
            }
            System.debug('===================logic:'+logic);
        }
        String sqlStr = '';
        String groupString = '';
        if(objectApi != null && objectApi.containsIgnoreCase(','))
        {
            sqlStr = 'select id dataId from ' + mainObject + ' where CreatedDate != null ';
            groupString = ' group by Id ';
        }
        else if(objectApi != null && objectApi.containsIgnoreCase('-'))
        {
            sqlStr = 'select ' + auxiliaryObject + ' dataId from ' + mainObject + ' where CreatedDate != null ';
            groupString = ' group by ' + auxiliaryObject + ' ';
        }
        else
        {
            sqlStr = 'select id dataId from ' + mainObject + ' where CreatedDate != null ';
            groupString = ' group by Id  ';
        }
        System.debug('================logic:'+logic);
        InDoSeachData inData = AssembleQueryConditions(logic,conditionList);
        System.debug('========inData:'+inData);
        if(inData != null && (inData.errorStr == null || inData.errorStr == '') && (inData.logicStr != null || inData.logicStr != ''))
        {
            if(logic != null && logic != '')
            {
                sqlStr = sqlStr + ' and ( ' + inData.logicStr + ' )';
            }
            if(userIds != null && userIds != '')
            {
                System.debug('====mainObject:'+mainObject+'===theObject:'+theObject+'===auxiliaryObject:'+auxiliaryObject);
                if(mainObject.equalsIgnoreCase(theObject)) //判断sql语句的from对象是不是操作数据的对象，如果是，则直接在sql语句中拼接【已分配=false】，如果不是则拼接字符串【查找字段__r.已分配=false】
                {
                    sqlStr = sqlStr + ' ';
                }
                else
                {
                    if(fieldMap.containsKey(auxiliaryObject) && fieldMap.get(auxiliaryObject).getDescribe().isCustom())
                    {
                        sqlStr = sqlStr + ' and '+auxiliaryObject.replace('__c','__r.')+' ';
                    }
                    else if(fieldMap.containsKey(auxiliaryObject) && !fieldMap.get(auxiliaryObject).getDescribe().isCustom())
                    {
                        sqlStr = sqlStr + ' and '+auxiliaryObject.replace('Id','.')+' ';
                    }
                }
                sqlStr = sqlStr + ' and ownerid in (\'' + userIds + '\')';
            }
            if(groupString != null && groupString != '')
            {
                sqlStr = sqlStr + groupString;
            }
        }
        System.debug('================sqlStr:'+sqlStr);
        return sqlStr;
    }

    //将筛选条件和筛选逻辑拼接成SQL语句。
    public String CheckConditions(List<Conditions> conditionList,String logic)
    {
        System.debug('=========auxiliaryObject:'+auxiliaryObject);
        if(logic == null || logic == '')
        {
            logic = '';
            for(Conditions con : conditionList)
            {
                System.debug('================con:'+con);
                if(con.fieldsName != null && con.fieldsName != '')
                {
                    if(logic == null || logic == '')
                    {
                        logic = ''+con.num;
                    }
                    else
                    {
                        logic = logic + ' and ' + con.num;
                    }
                }
                else
                {
                    continue;
                }
            }
            System.debug('===================logic:'+logic);
        }
        logic = logic.toUpperCase().replace('(', ' ( ').replace(')', ' ) ').replace('AND', ' AND ').replace('OR', ' OR ');
        String sqlStr = '';
        String groupString = '';
        if(objectApi != null && objectApi.containsIgnoreCase(','))
        {
            sqlStr = 'select id dataId from ' + mainObject + ' where CreatedDate != null ';
            groupString = ' group by Id ';
        }
        else if(objectApi != null && objectApi.containsIgnoreCase('-'))
        {
            sqlStr = 'select ' + auxiliaryObject + ' dataId from ' + mainObject + ' where CreatedDate != null ';
            groupString = ' group by ' + auxiliaryObject + ' ';
        }
        else
        {
            sqlStr = 'select id dataId from ' + mainObject + ' where CreatedDate != null ';
            groupString = ' group by Id ';
        }
        System.debug('================logic:'+logic);
        InDoSeachData inData = AssembleQueryConditions(logic,conditionList);
        System.debug('========inData:'+inData);
        if(inData != null && (inData.errorStr == null || inData.errorStr == '') && (inData.logicStr != null || inData.logicStr != ''))
        {
            System.debug('====mainObject:'+mainObject+'===theObject:'+theObject+'===auxiliaryObject:'+auxiliaryObject);
            if(mainObject.equalsIgnoreCase(theObject)) //判断sql语句的from对象是不是操作数据的对象，如果是，则直接在sql语句中拼接【已分配=false】，如果不是则拼接字符串【查找字段__r.已分配=false】
            {
                sqlStr = sqlStr + ' ';
            }
            else
            {
                if(fieldMap.containsKey(auxiliaryObject) && fieldMap.get(auxiliaryObject).getDescribe().isCustom())
                {
                    sqlStr = sqlStr + ' and '+auxiliaryObject.replace('__c','__r.')+' ';
                }
                else if(fieldMap.containsKey(auxiliaryObject) && !fieldMap.get(auxiliaryObject).getDescribe().isCustom())
                {
                    sqlStr = sqlStr + ' and '+auxiliaryObject.replace('Id','.')+' ';
                }
            }
            if(logic != null && logic != '')
            {
                sqlStr = sqlStr + ' and ( ' + inData.logicStr + ' )';
            }
            if(groupString != null && groupString != '')
            {
                sqlStr = sqlStr + groupString;
            }
        }
        System.debug('================sqlStr:'+sqlStr);
        return sqlStr;
    }

    //获取到对象的所有字段的Name和Label，并转为List<SelectOption>
    public List<SelectOption> FieldsMap()
    {
        System.debug('=====************^^^^^^^^^^^^^^^获取字段列表');
        System.debug('=================objectApi:'+objectApi);
        set<String> standFieldName = new set<String>();
        //standFieldName.add('Name');
        //standFieldName.add('CreatedDate');
        List<SelectOption> fieldsList = new List<SelectOption>();
        if(objectApi != null && objectApi.containsIgnoreCase(','))
        {
            //逗号分隔,格式：主对象,查找字段API
            mainObject = objectApi.split(',')[0];
            auxiliaryObject = objectApi.split(',')[1];
        }
        else if(objectApi != null && objectApi.containsIgnoreCase('-'))
        {
            //短横线分割,格式：子对象-子对象查找主对象的字段API
            mainObject = objectApi.split('-')[0];
            auxiliaryObject = objectApi.split('-')[1];
        }
        else
        {
            mainObject = objectApi;
        }
        
        //获取主对象上的所有字段
        Schema.SObjectType descResult = Schema.getGlobalDescribe().get(mainObject);
        fieldMap = descResult.getDescribe().fields.getMap();
        DofileName(fieldsList,fieldMap,standFieldName,descResult.getDescribe().getLabel(),false,null,auxiliaryObject);
        mainObjectLabel = descResult.getDescribe().getLabel();
                
        if(auxiliaryObject != null && auxiliaryObject != '' && fieldMap.containsKey(auxiliaryObject))
        {
            Schema.DescribeFieldResult lookupField = fieldMap.get(auxiliaryObject).getDescribe();
            Schema.sObjectType so = lookupField.getReferenceTo()[0];
            fieldMap2 = so.getDescribe().fields.getMap();
            auxiObjectLabel = so.getDescribe().getLabel();
            DofileName(fieldsList,fieldMap2,standFieldName,so.getDescribe().getLabel(),false,auxiliaryObject,auxiliaryObject);
        }

        return fieldsList;
    }

    /*  
        方法名:DofileName
        功能:字段API的选项列表值
        参数说明:
                fieldMap:对象的字段Map
                standFieldName:非自定义字段的API
                objectLable:对象Lable
                isAssociated:是否是关联对象
                lookUpFiled:查找字段的API
    */
    public List<SelectOption> DofileName(List<SelectOption> fieldsList,map <String, Schema.SObjectField>  fieldMaps, set<String> standFieldName, String objectLable, Boolean isAssociated,String lookUpFiled,String removeField)
    {
        fieldLableMap = new map<String,String>();
        if(lookUpFiled != null && lookUpFiled != '')
        {
            lookUpFiled = lookUpFiled.replace('__c','__r');
            if(lookUpFiled.endsWithIgnoreCase('id'))
            {
                lookUpFiled = lookUpFiled.replace('id','').replace('ID','').replace('iD','').replace('Id','');
            }
            lookUpFiled =lookUpFiled + '.';
        }
        
        for(String mk : fieldMaps.keyset())
        {
            System.debug('====='+mk);
            if(removeField != null && mk.containsIgnoreCase(removeField) && removeField != '')
            {
                continue;
            }
            
            if(String.valueOf(fieldMaps.get(mk).getDescribe().getType()).equalsIgnoreCase('TEXTAREA'))//文本域不能作为筛选条件，sql会报错
            {
                continue;
            }
            else if(fieldMaps.get(mk).getDescribe().isCustom() && !String.valueOf(fieldMaps.get(mk).getDescribe().getType()).equalsIgnoreCase('REFERENCE'))//自定义字段，且不为查找字段
            {
                if(lookUpFiled != null && lookUpFiled != '')
                {
                    fieldsList.add(new SelectOption(lookUpFiled+fieldMaps.get(mk).getDescribe().getName(),objectLable+':'+fieldMaps.get(mk).getDescribe().getLabel()));
                }
                else
                {
                    fieldsList.add(new SelectOption(fieldMaps.get(mk).getDescribe().getName(),objectLable+':'+fieldMaps.get(mk).getDescribe().getLabel()));
                }
                
            }
            else if(fieldMaps.get(mk).getDescribe().isCustom() && String.valueOf(fieldMaps.get(mk).getDescribe().getType()).equalsIgnoreCase('REFERENCE'))//自定义字段，且为查找字段
            {
                if(lookUpFiled != null && lookUpFiled != '')
                {
                    fieldsList.add(new SelectOption(lookUpFiled+fieldMaps.get(mk).getDescribe().getName().replace('__c','__r.Name'),objectLable+':'+fieldMaps.get(mk).getDescribe().getLabel()));
                }
                else
                {
                    fieldsList.add(new SelectOption(fieldMaps.get(mk).getDescribe().getName().replace('__c','__r.Name'),objectLable+':'+fieldMaps.get(mk).getDescribe().getLabel()));
                }
                
            }
            else if(!fieldMaps.get(mk).getDescribe().isCustom() && String.valueOf(fieldMaps.get(mk).getDescribe().getType()).equalsIgnoreCase('REFERENCE'))//非自定义字段，且为查找字段
            {
                if(lookUpFiled != null && lookUpFiled != '')
                {
                    fieldsList.add(new SelectOption(lookUpFiled+fieldMaps.get(mk).getDescribe().getName().replace('Id','.Name'),objectLable+':'+fieldMaps.get(mk).getDescribe().getLabel().replace(' ID', '')));
                }
                else
                {
                    fieldsList.add(new SelectOption(fieldMaps.get(mk).getDescribe().getName().replace('Id','.Name'),objectLable+':'+fieldMaps.get(mk).getDescribe().getLabel().replace(' ID', '')));
                }
            }
            else if(!fieldMaps.get(mk).getDescribe().isCustom())
            {// && standFieldName.contains(fieldMaps.get(mk).getDescribe().getName())
                if(lookUpFiled != null && lookUpFiled != '')
                {
                    fieldsList.add(new SelectOption(lookUpFiled+fieldMaps.get(mk).getDescribe().getName(),objectLable+':'+fieldMaps.get(mk).getDescribe().getLabel()));
                }
                else
                {
                    fieldsList.add(new SelectOption(fieldMaps.get(mk).getDescribe().getName(),objectLable+':'+fieldMaps.get(mk).getDescribe().getLabel()));
                }
            }
        }
        for(SelectOption so : fieldsList)
        {
            fieldLableMap.put(so.getValue(),so.getLabel());
        }
        return fieldsList;
    }
    public List<SelectOption> DofileName(List<SelectOption> fieldsList,map <String, Schema.SObjectField>  fieldMaps, set<String> standFieldName, String objectLable, String removeField)
    {
        return DofileName(fieldsList,fieldMaps,standFieldName,objectLable,false,null,removeField);
    }

    //创建运算符
    public void CreateOperator()
    {
        operMap = new map<String,String>();
        operMap.put('in','等于');
        operMap.put('not in','不等于');
        operMap.put('like','起始字符');
        operMap.put('contains','包含(文本中含有)');
        operMap.put('notContains','不包含(文本中不含有)');
        operMap.put('<','小于');
        operMap.put('>','大于');
        operMap.put('<=','小于或等于');
        operMap.put('>=','大于或等于');
        operMap.put('include','包括(多选中选择)');
        operMap.put('notInclude','不包括(多选中未选择)');
        
        operatorList = new List<SelectOption>();
        operatorList.add(new SelectOption('in','等于'));
        operatorList.add(new SelectOption('not in','不等于'));
        operatorList.add(new SelectOption('like','起始字符'));
        operatorList.add(new SelectOption('contains','包含(文本中含有)'));
        operatorList.add(new SelectOption('notContains','不包含(文本中不含有)'));
        operatorList.add(new SelectOption('<','小于'));
        operatorList.add(new SelectOption('>','大于'));
        operatorList.add(new SelectOption('<=','小于或等于'));
        operatorList.add(new SelectOption('>=','大于或等于'));
        operatorList.add(new SelectOption('include','包括(多选中选择)'));
        operatorList.add(new SelectOption('notInclude','不包括(多选中未选择)'));
    }

    public void GetPickListValueDo(String fieldName,List<MetadataFieldClass.Conditions> conditionList,String passedParam2)
    {
        List<SelectOpValue> optionMap = null;
        List<checkSelectOption> valueList = null;
        String passedParam1 = null;
        String thelabel = null;
        String fieldLabel = null;
        if(fieldName == null)
        {
        	fieldName = '';
        }
        System.debug('=============fieldName:'+fieldName);
        if(fieldName.contains('__r.Name'))//处理自定义的查找字段的API名，将sobject__r.Name转换为sobject__c;
        {
            fieldName = fieldName.replace('__r.Name','__c');
        }
        if(fieldName.contains('.Name'))//处理标准的查找字段的API名，将Sobject.Name转换为SobjectId。
        {
            fieldName = fieldName.replace('.Name','Id');
        }
        if(fieldName.contains('__r.'))
        {
            passedParam1 = fieldName.subString(fieldName.indexOf('__r.')+'__r.'.length());
        }
        else
        {
            passedParam1 = fieldName;
        }
        System.debug('======++++++++++=======:'+passedParam1);
        String fieldsType = '';
        Schema.SObjectField sobjectField = null;
        if(!fieldName.contains('__r.') && fieldMap.containsKey(passedParam1))
        {
            sobjectField = fieldMap.get(passedParam1);
            fieldLabel = mainObjectLabel;
        }
        else if(fieldName.contains('__r.') && fieldMap2.containsKey(passedParam1))
        {
            sobjectField = fieldMap2.get(passedParam1);
            fieldLabel = auxiObjectLabel;
        }
        else if(passedParam1.contains('.'))
        {
            passedParam1 = passedParam1.subString(passedParam1.indexOf('.')+1);
            if(fieldMap2.containsKey(passedParam1))
            {
                sobjectField = fieldMap2.get(passedParam1);
                fieldLabel = auxiObjectLabel;
            }
        }
        if(null != sobjectField && null != sobjectField.getDescribe())
        {
            fieldsType = String.valueOf(sobjectField.getDescribe().getType());
            fieldLabel = fieldLabel + ':' + String.valueOf(sobjectField.getDescribe().getLabel());
        }
        else
        {
            return;
        }
        if(passedParam1 == '' || passedParam1 == null)
        {
            for(Conditions c : conditionList)
            {
                if(c.num == Integer.valueOf(passedParam2))
                {
                    c.selectOp = null;
                    c.labels = null;
                }else{
                    continue;
                }
            }
        }
        else if( 'PICKLIST'.equalsIgnoreCase(String.valueOf(sobjectField.getDescribe().getType())) || 'MULTIPICKLIST'.equalsIgnoreCase(String.valueOf(sobjectField.getDescribe().getType())))
        {
            optionMap = new List<SelectOpValue>();
            valueList = new List<checkSelectOption>();
            
            List<Schema.PicklistEntry> fieldOptions = sobjectField.getDescribe().getPicklistValues();
            for(Schema.PicklistEntry sp : fieldOptions)
            {
                SelectOpValue sov = new SelectOpValue();
                sov.key = sp.getValue();
                sov.value = sp.getLabel();
                optionMap.add(sov);
            }
        }
        else if( 'BOOLEAN'.equalsIgnoreCase(String.valueOf(sobjectField.getDescribe().getType())))
        {
            optionMap = new List<SelectOpValue>();

            SelectOpValue sov1 = new SelectOpValue();
            sov1.key = 'true';
            sov1.value = '是';

            SelectOpValue sov2 = new SelectOpValue();
            sov2.key = 'false';
            sov2.value = '否';

            optionMap.add(sov1);
            optionMap.add(sov2);
        }
        else
        {
            for(Conditions c : conditionList)
            {
                if(c.num == Integer.valueOf(passedParam2))
                {
                    c.selectOp = null;
                    c.labels = null;
                }else{
                    continue;
                }
            }
        }
        for(Conditions c : conditionList)
        {
            if(c.num == Integer.valueOf(passedParam2))
            {
                c.selectOp = optionMap;
                c.fieldsType = fieldsType;
                c.labels = thelabel;
                c.fieldsLabel = fieldLabel;
            }else{
                continue;
            }
        }
    }
    
    /*
        方法名:AssembleQueryConditions
        功能:传入查询条件的List和筛选逻辑之后，将查询条件和筛选逻辑拼装成可以用于SQL语句中作为where条件的字符串
        参数说明:
            logicStr:筛选逻辑
        作者:Jimmy
        时间:2017-08-15
    */
    public InDoSeachData AssembleQueryConditions(String logicStr,List<Conditions> conditionList)
    {
        logicStr = ' ' + logicStr + ' ';
        InDoSeachData InData = new InDoSeachData();
        set<String> noString = new set<String>();
        noString.add('like');//起始字符
        noString.add('contains');//包含
        noString.add('notContains');//不包含
        noString.add('include');//包括
        noString.add('notInclude');//不包括
        String errorStr = '';
        String passedParam1 = '';
        for(integer i=0;i<=conditionList.size()-1;i++)//循环筛选条件List
        {
            Conditions con = conditionList[i];
            if(null != con.fieldsValue)
            {
                con.fieldsValue = con.fieldsValue.replace('\'','');
                con.fieldsValue = con.fieldsValue.replace(',','\',\'');
            }
            String fieldName = '';  
            if(con.fieldsName == null || con.fieldsName == '')
            {
               continue;
            }
            else 
            {
                String fieldStr = con.fieldsName;
                if(fieldStr.contains('__r.Name'))//处理自定义的查找字段的API名，将sobject__r.Name转换为sobject__c;
                {
                    fieldStr = fieldStr.replace('__r.Name','__c');
                }
                if(fieldStr.contains('.Name'))//处理标准的查找字段的API名，将Sobject.Name转换为SobjectId。
                {
                    fieldStr = fieldStr.replace('.Name','Id');
                }
                if(fieldStr.contains('__r.'))
                {
                    passedParam1 = fieldStr.subString(fieldName.indexOf('__r.')+'__r.'.length());
                }
                else
                {
                    passedParam1 = fieldStr;
                }
                String fieldsType = '';
                Schema.SObjectField sobjectField = null;
                if(fieldMap.containsKey(passedParam1))
                {
                    sobjectField = fieldMap.get(passedParam1);
                }
                else if(fieldMap2 != null && fieldMap2.containsKey(passedParam1))
                {
                    sobjectField = fieldMap2.get(passedParam1);
                }
                else if(passedParam1.contains('.'))
                {
                    passedParam1 = passedParam1.subString(passedParam1.indexOf('.')+1);
                    if(fieldMap2 != null && fieldMap2.containsKey(passedParam1))
                    {
                        sobjectField = fieldMap2.get(passedParam1);
                    }
                } 
                
                if(sobjectField == null)
                {
                    return null;
                }

                if(con.operator == null || con.operator == '') //没有填写运算符
                {
                    errorStr = '请输入正确的筛选条件！';
                }
                else if(!String.valueOf(sobjectField.getDescribe().getSOAPType()).equalsIgnoreCase('STRING') && (con.fieldsValue == '' || con.fieldsValue == null))
                {
                    errorStr = '请输入正确的筛选条件！';
                }
                else if(String.valueOf(sobjectField.getDescribe().getSOAPType()).equalsIgnoreCase('STRING') && (con.operator == '<' || con.operator == '>' || con.operator == '<=' || con.operator == '>='))
                {
                    errorStr = '请输入正确的筛选条件！';
                }
                else if((String.valueOf(sobjectField.getDescribe().getSOAPType()).equalsIgnoreCase('STRING') || con.fieldsName.contains('.Name')) && (!noString.contains(con.operator)))//字段接收值的类型为String，并且运算符不是特殊运算符
                {
                    String condi = null;
                    if(con.fieldsValue != null && con.fieldsValue != '' && con.fieldsValue != 'null')
                    {
                        condi = ' ' + con.fieldsName + ' ' + con.operator + '( \'' + con.fieldsValue + '\')';
                    }
                    else
                    {
                        condi = ' ' + con.fieldsName + ' ' + con.operator + '( null )';
                    }
                    System.debug('========condi:'+condi);
                    System.debug('===========logicStr:'+logicStr);
                    logicStr = logicStr.replace(' '+con.num+' ',' ( '+condi+' )');
                    System.debug('==============logicStr:'+logicStr);
                }
                else if((String.valueOf(sobjectField.getDescribe().getSOAPType()).equalsIgnoreCase('STRING') == false) &&(!noString.contains(con.operator))) //字段接收值不为String，并且运算符不为特殊运算符
                {
                    String condi = null;
                    if(String.valueOf(sobjectField.getDescribe().getType()).equalsIgnoreCase('DATETIME'))
                    {
                        if(con.fieldsValue == '今天' || con.fieldsValue.equalsIgnoreCase('today'))
                        {
                            condi = ' ' + con.fieldsName+' ' +con.operator + '  today ';
                        }
                        else
                        {
                            //String.valueOf(DateTime.newInstance(Long.valueOf(cdrRec.substring(cdrRec.length()-16,cdrRec.length()))/1000).format('yyyy-MM-dd','Asia/Shanghai'));
                            //数据库中的时间为格林尼治时间，需要在本地时间上减去8小时
                            //一天的开始时间【dateBegin】 和一天的结束时间【dateEnd】
                            DateTime dateBegin = Datetime.valueOf(con.fieldsValue +' 00:00:00');
                            DateTime dateEnd = Datetime.valueOf(con.fieldsValue +' 23:59:59');
                            System.debug('==============='+Datetime.valueOf(con.fieldsValue +' 00:00:00')+'============'+Datetime.valueOf(con.fieldsValue +' 23:59:59'));
                            System.debug('=============dateBegin:'+dateBegin+'======dateEnd:'+dateEnd);
                            String dateBeginStr = null;
                            String dateEndStr = null;
                            
                            //将日期时间格式的数据拼接成一个能够被数据库识别的字符串
                            if(dateBegin != null)
                            {
                                dateBeginStr = String.valueOf(dateBegin).replace(' ','T')+'.000+0000';
                            }
                            if(dateEnd != null)
                            {
                                dateEndStr = String.valueOf(dateEnd).replace(' ','T')+'.000+0000';
                            }
                            
                            if(con.operator == '<=')
                            {
                                condi = ' ' + con.fieldsName+' ' +con.operator + '  '+dateEndStr +' ';
                            }
                            else if(con.operator == '>=')
                            {
                                condi = ' ' + con.fieldsName+' ' +con.operator + '  '+ dateBeginStr +' ';
                            } 
                            else if(con.operator=='in')
                            {
                                condi = '  '+ con.fieldsName + ' >= ' +dateBeginStr+'   and  '+con.fieldsName+'   <=   '+dateEndStr +' ';
                            }
                            else if(con.operator=='not in')
                            {
                                condi = ' ('+ con.fieldsName+'  <=  '+dateBeginStr+'    or   '+con.fieldsName+'  >=  '+dateEndStr +')  ';
                            }
                            else if(con.operator=='>')
                            {
                                condi = ' ' + con.fieldsName+' ' +con.operator + '  '+ dateEndStr +' ';
                            }
                            else if(con.operator=='<')
                            {
                                condi = ' ' + con.fieldsName+' ' +con.operator + '  '+ dateBeginStr +' ';
                            }
                            
                            System.debug('========con.num:'+con.num+'=====condi:'+condi);
                        }
                    }
                    else
                    {
                        if(con.operator == '<=' || con.operator == '>=' || con.operator == '<' || con.operator == '>')
                        {
                            condi = ' ' + con.fieldsName + ' ' + con.operator + ' ' + con.fieldsValue+' ';
                        }
                        else if(con.fieldsValue != null && con.fieldsValue != ''){
                            condi =  ' ' + con.fieldsName + ' ' + con.operator + ' (' + con.fieldsValue+') ';
                        }
                        else if(con.fieldsValue == null || con.fieldsValue == '')
                        {
                            condi =  ' ' + con.fieldsName + ' ' + con.operator + ' ( null ) ';
                        }
                    }
                    logicStr = logicStr.replace(' '+con.num+' ',' ( '+condi+' )');
                }
                else if((String.valueOf(sobjectField.getDescribe().getSOAPType()).equalsIgnoreCase('STRING') || con.fieldsName.contains('.Name'))  && con.operator == 'like')
                {
                    String condi = null;
                    condi = ' ' + con.fieldsName + ' Like \''+con.fieldsValue+'%\' ';
                    logicStr = logicStr.replace(' '+con.num+' ',' ( '+condi+' )');
                }
                else if((String.valueOf(sobjectField.getDescribe().getSOAPType()).equalsIgnoreCase('STRING') || con.fieldsName.contains('.Name')) && con.operator == 'contains')
                {
                    String condi = null;
                    condi = ' ' + con.fieldsName + ' Like \'%'+con.fieldsValue+'%\' ';
                    logicStr = logicStr.replace(' '+con.num+' ',' ( '+condi+' )');
                }
                else if((String.valueOf(sobjectField.getDescribe().getSOAPType()).equalsIgnoreCase('STRING') || con.fieldsName.contains('.Name')) && con.operator == 'notContains')
                {
                    String condi = null;
                    condi =' ' +' (not ' + con.fieldsName + ' Like \'%'+con.fieldsValue+'%\')   ';
                    logicStr = logicStr.replace(' '+con.num+' ',' ( '+condi+' )');
                }
                else if((String.valueOf(sobjectField.getDescribe().getSOAPType()).equalsIgnoreCase('STRING') || con.fieldsName.contains('.Name')) && con.operator == 'notInclude')
                {   
                    String condi = null;
                    if(con.fieldsValue != null && con.fieldsValue != '')
                    {
                        condi = ' '+' ( not ' + con.fieldsName + ' includes (\''+con.fieldsValue+'\')) '+' ';
                    }
                    else
                    {
                        condi = ' '+' ( not ' + con.fieldsName + ' includes ( null ))   ';
                    }
                    logicStr = logicStr.replace(' '+con.num+' ',' ( '+condi+' )');
                }
                else if((String.valueOf(sobjectField.getDescribe().getSOAPType()).equalsIgnoreCase('STRING') || String.valueOf(sobjectField.getDescribe().getSOAPType()).contains('.Name'))  && con.operator == 'include')
                {
                    String condi = null;
                    if(con.fieldsValue != null && con.fieldsValue != '')
                    {
                        condi = ' ' + con.fieldsName + ' includes (\''+con.fieldsValue+'\')  ';
                    }
                    else
                    {
                        condi = ' ' + con.fieldsName + ' includes ( null )   ';
                    }
                    logicStr = logicStr.replace(' '+con.num+' ',' ( '+condi+' )');
                }
            }
        }
        InData.errorStr = errorStr;
        System.debug('=============logicStr:'+logicStr);
        InData.logicStr = logicStr;
        return InData;
    }
    
    public String GetConditionalText(List<Conditions> conditionList)
    {
        String conditionalText = '';
        String passedParam1 = '';
        String objectLabel = '';
        for(integer i=0;i<=conditionList.size()-1;i++)//循环筛选条件List
        {
            Conditions con = conditionList[i];
            if(null != con.fieldsValue)
            {
                con.fieldsValue = con.fieldsValue.replace('\'','');
                con.fieldsValue = con.fieldsValue.replace(',','\',\'');
            }
            String fieldName = '';  
            if(con.fieldsName == null || con.fieldsName == '')
            {
               continue;
            }
            else 
            {
                if(fieldLableMap.containsKey(con.fieldsName))
                {
                    conditionalText = conditionalText + con.num + '、' + fieldLableMap.get(con.fieldsName) +' '+ operMap.get(con.operator) + ' '+ con.fieldsValue+';\n\r';               
                }
            }
        }
        return conditionalText;
    }
    

    public class checkSelectOption
    {
        public boolean checkbox{get;set;}//复选框
        public String valueStr{get;set;}//value
        public String labelStr{get;set;}//label
        public String label{get;set;}//label
    }

    public class Conditions
    {
        public integer num{get;set;}//序号
        public boolean checkbox{get;set;}//复选框
        public String fieldsName{get;set;}//字段API
        public String operator{get;set;}//运算符
        public String fieldsValue{get;set;}//字段值
        public String fieldsValueLabel{get;set;} //选项列表类型字段的值
        public String fieldsLabel{get;set;}//字段标签
        public List<SelectOpValue> selectOp{get;set;}//真/假
        public String fieldsType{get;set;}//字段类型
        public String labels{get;set;}//选项列表字段的字段值
    }
    public class SelectOpValue {
        public boolean isChecked{get;set;}
		public String value{get;set;}
		public String key{get;set;}
	}
    public class InDoSeachData
    {
        public String  errorStr{set;get;}//错误信息
        public String  logicStr{set;get;}//拼接sql的字符串
    }
}