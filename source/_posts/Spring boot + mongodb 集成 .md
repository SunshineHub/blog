---
title: Spring boot + mongodb 集成
cover: /images/1680.jpg
date: 2018-9-28 10:36:53
subtitle: 123
author: 
  name: oijok
  link: https://github.com/Mrminfive
tags:
 - java 
 - excel 
categories:
 - excel
---
Spring Boot对各种流行的数据源都进行了封装，当然也包括了mongodb,下面介绍如何在spring boot中使用mongodb：

# pom包配置
pom包里面添加spring-boot-starter-data-mongodb包引用

```
<dependencies>
	<dependency> 
	    <groupId>org.springframework.boot</groupId>
	    <artifactId>spring-boot-starter-data-mongodb</artifactId>
	</dependency> 
</dependencies>
```
# 在application.properties中添加配置

`spring.data.mongodb.uri=mongodb://admin:123456@localhost:27017/tj_workorder`

## 多个IP集群可以采用以下配置：

`spring.data.mongodb.uri=mongodb://user:pwd@ip1:port1,ip2:port2/database`

# 创建数据实体

```
package com.tj.workorder.domain.mongo;

import java.util.ArrayList;
import com.tj.workorder.domain.mongo.util.MongoQueryUtil;
import java.util.List;
import com.tj.workorder.util.QueryCondition;

import lombok.Getter;
import lombok.Setter;
import org.apache.commons.lang3.StringUtils;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;

import com.tj.workorder.util.QueryCondition;

import lombok.Getter;
import lombok.Setter;

/**
 * 
 * @author wangch
 *
 */
@Setter
@Getter
@Document(collection = "workOrderDefault")
public class WorkOrderDefault extends QueryCondition{
	private static final long serialVersionUID = -1L;

	@Id
	private String  id;
	/**
	 * 工单标题
	 * */
	private String workOrderName;
	/**
	 * 字段对象
	 * */
	private List<WorkOrderDictionary> dictionary;
	/**
	 * 是否可编辑  0：不可编辑    1：可编辑
	 *
	 * */
	private Integer editable;

	/**
	 * 工单状态  0：关闭   1：开启
	 * */
	private Integer status;

	public Criteria[] queryReady(){
		return MongoQueryUtil.queryReady(this);
	}

	public Update updateByIdReady(){
		return MongoQueryUtil.updateByIdReady(this);
		/*Update update = new Update();
		List<WorkOrderDictionary> dictionary = this.getDictionary();
		if (this.getStatus()!=null) {
			update.set("status",this.getStatus());
		}
		if (this.getEditable()!=null) {
			update.set("editable",this.getEditable());
		}
		if (StringUtils.isNotEmpty(this.getWorkOrderName())) {
			update.set("workOrderName",this.getWorkOrderName());
		}
		if (dictionary!=null&&dictionary.size()>0) {
			update.set("dictionary",dictionary);
		}*/

	}

	/*public Criteria[] queryReady(WorkOrderDefault workOrderDefault) {
		List<Criteria> criteriaList = new ArrayList<Criteria>();
		if (workOrderDefault.getId() != null) {
			criteriaList.add(Criteria.where("_id").is(workOrderDefault.getId()));
		}
		if (StringUtils.isNotEmpty(workOrderDefault.getWorkOrderName())) {
			criteriaList.add(Criteria.where("workOrderName").is(workOrderDefault.getWorkOrderName()));
		}
		if (workOrderDefault.getStatus() != null) {
			criteriaList.add(Criteria.where("status").is(workOrderDefault.getStatus()));
		}
		if (workOrderDefault.getEditable() != null) {
			criteriaList.add(Criteria.where("editable").is(workOrderDefault.getEditable()));
		}
		Criteria[] criteria = criteriaList.toArray(new Criteria[]{});
		return criteria;
	}*/
	
}


package com.tj.workorder.domain.mongo.util;

import com.tj.workorder.web.controller.BaseController;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Update;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
/**
 * 实体类查询、更新条件工具类
 * */
public class MongoQueryUtil {

    protected static final Logger logger = LoggerFactory.getLogger(BaseController.class) ;
    public static Criteria[] queryReady(Object o) {
        List<Criteria> criteriaList = new ArrayList<Criteria>();
        try {
            Method[] methods = o.getClass().getDeclaredMethods();
            for (int i = 0; i < methods.length; i++) {
                Method method = methods[i];
                if (method.getName().startsWith("get")) {
                    String field = method.getName().substring(3, method.getName().length());
                    field = field.substring(0, 1).toLowerCase() + field.substring(1, field.length());
                    if(o.getClass().getDeclaredField(field).getAnnotation(Id.class) != null){
                        field = "_id";
                    }
                    Object invoke = method.invoke(o);
                    if (invoke != null) {
                        criteriaList.add(Criteria.where(field).is(invoke));
                    }
                }
            }
        } catch (IllegalAccessException | InvocationTargetException | NoSuchFieldException e) {
            logger.error("查询失败",e);
            e.printStackTrace();
        }
        return criteriaList.size() == 0 ? null : criteriaList.toArray(new Criteria[]{});
    }
    public static Update updateByIdReady(Object o){
        Update update = new Update();
        try {
        Method[] methods = o.getClass().getDeclaredMethods();
        for (int i = 0; i < methods.length; i++) {
            Method method = methods[i];
            if (method.getName().startsWith("get")) {
                String field = method.getName().substring(3, method.getName().length());
                field = field.substring(0, 1).toLowerCase() + field.substring(1, field.length());
                if(o.getClass().getDeclaredField(field).getAnnotation(Id.class) != null){
                    field = "_id";
                }
                Object invoke = method.invoke(o);
                if (invoke != null) {
                    update.set(field, invoke);
                }
            }
        }
    } catch (IllegalAccessException | InvocationTargetException | NoSuchFieldException e) {
        logger.error("更新失败",e);
        e.printStackTrace();
    }
        return update;
    }

}

```
# 创建Controller
```
package com.tj.workorder.web.controller;

import com.github.pagehelper.PageInfo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.web.bind.annotation.RequestMapping;

import com.mongodb.WriteResult;
import com.tj.workorder.domain.mongo.WorkOrderDefault;
import com.tj.workorder.service.WorkOrderService;
import com.tj.workorder.util.UrlUtil;
import com.tj.common.lang.JsonResultBuilder.JsonResult;
import org.springframework.web.bind.annotation.RestController;



@RestController
@RequestMapping(value = "/workOrder")
public class WorkOrderController extends BaseController {
	@Autowired
	private WorkOrderService workOrderService;

	@RequestMapping(value = "/saveWorkOrder", produces = "application/json;charset=utf-8")
	public JsonResult<WorkOrderDefault> saveWorkOrder(WorkOrderDefault workOrder){
        logger.info(-----------模拟保存数据开始-----------)
		workOrder.setEditable(1);
		//默认关闭
        workOrder.setStatus(0);
        
		List<WorkOrderDictionary> list = new ArrayList<>();

		for (int i = 0; i <4 ; i++) {
			WorkOrderDictionary dictionary = new WorkOrderDictionary("测试字段"+i,"text" , 1,1,"test",i+1);
			if (i==2){
				dictionary.setType("select");
				dictionary.setValue("测试1,测试2");
			}

			list.add(dictionary);
		}
		workOrder.setDictionary(list);
        String url = UrlUtil.createUrl(11L,"");
        workOrder.setUrl(url);
        logger.info(-----------模拟保存数据结束-----------)
        WorkOrderDefault workOrderDefault = workOrderService.save(workOrder);
        return super.sucessAjax("新建工单成功",workOrderDefault);
	}
    /**
     * 简单分页查询（不带查询条件）
     * */
    @RequestMapping(value = "/queryWorkOrder", produces = "application/json;charset=utf-8")
    public JsonResult<Page<WorkOrderDefault>> queryWorkOrder(WorkOrderDefault workOrder) throws Exception{
        if (workOrder.getPageNo() == null) {
            workOrder.setPageNo(1);
            workOrder.setPageSize(10);
        }
        Page<WorkOrderDefault>   workOrderDefaults = workOrderService.findPage(workOrder.getPageNo(), workOrder.getPageSize(),null);
        return super.sucessAjax("成功",workOrderDefaults);
    }
    /**
     * 复杂分页查询（带查询条件）
     * */
    @RequestMapping(value = "/queryWorkOrders", produces = "application/json;charset=utf-8")
    public JsonResult<PageInfo<WorkOrderDefault>> queryWorkOrders(WorkOrderDefault workOrder) throws Exception{
        workOrder.setPageSize(2);
        workOrder.initPagination();
        PageInfo<WorkOrderDefault> pagination = workOrderService.queryWorkOrderByPage(workOrder);
        return super.sucessAjax("成功",pagination);
    }

    /**
     * 修改工单字段
     * */
    @RequestMapping(value = "/updateWorkOrder", produces = "application/json;charset=utf-8")
    public JsonResult<WriteResult> updateWorkOrderById(WorkOrderDefault workOrder) throws Exception{
        WriteResult result = workOrderService.update(workOrder);
        if (result.getN()>0) {
            return super.sucessAjax("修改"+result.getN()+"条记录",result);
        }
        return super.failureAjax("没有发现修改项",null);
    }
    @RequestMapping(value = "/deleteWorkOrder", produces = "application/json;charset=utf-8")
    public JsonResult<Void> deleteWorkOrderById(String id) throws Exception{
        if (id != null) {
            workOrderService.delete(id);
            return super.sucessAjax("删除成功",null);
        }
        return super.failureAjax("没有发现修改项",null);
    }
}
```
# 创建BaseService
```
package com.tj.workorder.service.base.impl;

import com.tj.workorder.service.base.BaseMongoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.io.Serializable;
import java.util.List;

public class BaseMongoServiceImpl<T,ID extends Serializable> implements BaseMongoService<T ,ID>{
    @Autowired
    private MongoRepository<T,ID> mongoRepository;

    @Override
    public <S extends T> S save(S var1) {
        return (S) mongoRepository.save(var1);
    }

    @Override
    public List<T> findAll() {
        return mongoRepository.findAll();
    }

    @Override
    public Page<T> findAll(Integer pageNo, Integer size) {
        return mongoRepository.findAll(new PageRequest(pageNo-1,size));
    }

    @Override
    public long count() {
        return mongoRepository.count();
    }

    @Override
    public void delete(ID var1) {
        mongoRepository.delete(var1);
    }

    @Override
    public void delete(T var1) {
        mongoRepository.delete(var1);
    }

    @Override
    public void deleteAll() {
        mongoRepository.deleteAll();
    }
}

```

# 创建Service接口
```
package com.tj.workorder.service;


import com.github.pagehelper.PageInfo;
import com.mongodb.WriteResult;
import com.tj.workorder.domain.mongo.WorkOrderDefault;
import com.tj.workorder.service.base.BaseMongoService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Sort;

public interface WorkOrderService extends BaseMongoService<WorkOrderDefault , String>{

    public Page<WorkOrderDefault> findPage(Integer pageNo , Integer pageSize , Sort sort) throws Exception;
    /**
    *分页复杂查询
    * */
    public PageInfo<WorkOrderDefault> queryWorkOrderByPage(WorkOrderDefault workOrder) throws Exception;
    /**
     * 更新
     * */
    public WriteResult update (WorkOrderDefault workOrder) throws Exception;

}
```
# 创建实现类
```
package com.tj.workorder.service.impl;

import com.github.pagehelper.PageInfo;
import com.mongodb.WriteResult;
import com.tj.workorder.dao.WorkOrderDao;
import com.tj.workorder.domain.mongo.WorkOrderDefault;
import com.tj.workorder.service.WorkOrderService;
import com.tj.workorder.service.base.impl.BaseMongoServiceImpl;
import com.tj.workorder.util.PageInfoBuilder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoOperations;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Service;

import java.util.List;

@Service("workOrderService")
public class WorkOrderServiceImpl extends BaseMongoServiceImpl<WorkOrderDefault ,String> implements WorkOrderService {
    @Autowired
    MongoOperations mongoTemplate;
    @Autowired
    private WorkOrderDao workOrderDao;


    @Override
    public org.springframework.data.domain.Page<WorkOrderDefault> findPage(Integer pageNo, Integer pageSize , Sort sort) throws Exception{

        Pageable pageable = new PageRequest(pageNo-1,pageSize,sort);
        return workOrderDao.findAll(pageable);
    }

    @Override
    public PageInfo<WorkOrderDefault> queryWorkOrderByPage(WorkOrderDefault workOrder) throws Exception{
        Query query = new Query();
        Criteria[] queryCriteria = workOrder.queryReady();
        if (queryCriteria.length>0) {
            Criteria criteria = new Criteria().andOperator(queryCriteria);
            query.addCriteria(criteria);
        }
        query.skip(workOrder.getStart());
        query.limit(workOrder.getOffset());
        List<WorkOrderDefault> workOrderDefaults = mongoTemplate.find(query, WorkOrderDefault.class);
        long count = mongoTemplate.count(query, WorkOrderDefault.class);
        PageInfo pageInfo = new PageInfoBuilder<WorkOrderDefault>().build(workOrderDefaults, count, workOrder.getPageSize(),workOrder.getPageNo());
        return pageInfo;
    }

    @Override
    public WriteResult update(WorkOrderDefault workOrder) throws Exception{
        Query query  = new Query(Criteria.where("_id").is(workOrder.getId()));
        Update update = workOrder.updateByIdReady(query);
        WriteResult writeResult = mongoTemplate.updateFirst(query, update, WorkOrderDefault.class);
        return writeResult;
    }
}

```
# 封装分页的工具类
```
package com.tj.workorder.util;

import com.github.pagehelper.PageInfo;

import java.util.List;


/**
 * 封装分页工具类
 * 
 * @author wangch
 *
 */
public class PageInfoBuilder<T> {
	public  PageInfo<T> build(List<T> list , long count , Integer pageSize , Integer currentPage , int navigatePages){
		PageInfo<T> pagination = new PageInfo<>();
		pagination.setList(list);
		pagination.setTotal(count);
		pagination.setPageSize(pageSize);
		pagination.setPageNum(currentPage);
		pagination.setNavigatePages(navigatePages);
		pagination.setSize(list.size());
		int totalPage = calculateTotalPage(count, pageSize);
		pagination.setPages(totalPage);
		pagination.setNavigatepageNums(calcNavigatepageNums(totalPage,navigatePages,currentPage));
		calcPage(pagination);
		judgePageBoudary(pagination);
		return pagination;
	}
	public PageInfo<T> build(List<T> list , long count , Integer pageSize , Integer currentPage){
		return build(list,count,pageSize,currentPage,5);
	}
	private static int calculateTotalPage(long count , Integer pageSize){
		int totalPage = 0 ;
		if(pageSize==0){
			totalPage = 1;
			return totalPage;
		}
		int totalCount = Long.valueOf(count).intValue();
		// 计算总页数
		totalPage = totalCount%pageSize == 0 ? totalCount/pageSize : totalCount/pageSize+1;
		return totalPage;
	}

	private static int[] calcNavigatepageNums(int pages , int navigatePages , int pageNum) {
		int i;
		int[] navigatepageNums;
		if (pages <= navigatePages) {
			navigatepageNums = new int[pages];

			for(i = 0; i < pages; ++i) {
				navigatepageNums[i] = i + 1;
			}
		} else {
			navigatepageNums = new int[navigatePages];
			i = pageNum - navigatePages / 2;
			int endNum = pageNum + navigatePages / 2;
//            int i;
			if (i < 1) {
				i = 1;

				for(i = 0; i < navigatePages; ++i) {
					navigatepageNums[i] = i++;
				}
			} else if (endNum > pages) {
				endNum = pages;

				for(i = navigatePages - 1; i >= 0; --i) {
					navigatepageNums[i] = endNum--;
				}
			} else {
				for(i = 0; i < navigatePages; ++i) {
					navigatepageNums[i] = i++;
				}
			}
		}
		return navigatepageNums;
	}
	private static void calcPage(PageInfo pageInfo) {
		int[] navigatepageNums = pageInfo.getNavigatepageNums();
		if (navigatepageNums != null && navigatepageNums.length > 0) {
			pageInfo.setNavigateFirstPage(navigatepageNums[0]);
			pageInfo.setNavigateLastPage(navigatepageNums[navigatepageNums.length-1]);
			if (pageInfo.getPageNum() > 1) {
				pageInfo.setPrePage(pageInfo.getPageNum()-1);
			}

			if (pageInfo.getPageNum() <pageInfo.getPages()) {
				pageInfo.setNextPage(pageInfo.getPageNum()+1);
			}
		}
	}
	private static void judgePageBoudary(PageInfo pageInfo) {
		pageInfo.setIsFirstPage(pageInfo.getPageNum() == 1);
		pageInfo.setIsLastPage(pageInfo.getPageNum() == pageInfo.getPages() || pageInfo.getPages() == 0);
		pageInfo.setHasPreviousPage(pageInfo.getPageNum()>1);
		pageInfo.setHasNextPage(pageInfo.getPageNum()<pageInfo.getPages());
	}
}

```
# 创建Dao
```
package com.tj.workorder.dao;

import com.tj.workorder.domain.mongo.WorkOrderDefault;
import org.springframework.data.mongodb.repository.MongoRepository;


/**
 * 
 * @author Wangch
 *
 */
public interface WorkOrderDao extends MongoRepository<WorkOrderDefault,String> {
}

```
# 测试
访问地址：
 >
 http://localhost:2080/tj-workorder-web/workOrder/queryWorkOrders
最终结果：
```
{
    "msg":"成功",
    "success":true,
    "data":{
        "pageNum":1,
        "pageSize":2,
        "size":2,
        "startRow":0,
        "endRow":0,
        "total":4,
        "pages":2,
        "list":[
            {
                "pageNo":1,
                "pageSize":10,
                "start":null,
                "offset":null,
                "id":"5a0bb3dce9d75832105bb9fa",
                "workOrderName":null,
                "dictionary":[
                    {
                        "title":"测试字段0",
                        "type":"text",
                        "isRequired":1,
                        "visible":1,
                        "value":"test",
                        "sort":1
                    },
                    {
                        "title":"测试字段1",
                        "type":"text",
                        "isRequired":1,
                        "visible":1,
                        "value":"test",
                        "sort":2
                    },
                    {
                        "title":"测试字段2",
                        "type":"select",
                        "isRequired":1,
                        "visible":1,
                        "value":"测试1,测试2",
                        "sort":3
                    },
                    {
                        "title":"测试字段3",
                        "type":"text",
                        "isRequired":1,
                        "visible":1,
                        "value":"test",
                        "sort":4
                    }
                ],
                "editable":1,
                "status":0,
                "url":""
            },
            {
                "pageNo":1,
                "pageSize":10,
                "start":null,
                "offset":null,
                "id":"5a0bb3e0e9d75832105bb9fb",
                "workOrderName":null,
                "dictionary":[
                    {
                        "title":"测试字段0",
                        "type":"text",
                        "isRequired":1,
                        "visible":1,
                        "value":"test",
                        "sort":1
                    },
                    {
                        "title":"测试字段1",
                        "type":"text",
                        "isRequired":1,
                        "visible":1,
                        "value":"test",
                        "sort":2
                    },
                    {
                        "title":"测试字段2",
                        "type":"select",
                        "isRequired":1,
                        "visible":1,
                        "value":"测试1,测试2",
                        "sort":3
                    },
                    {
                        "title":"测试字段3",
                        "type":"text",
                        "isRequired":1,
                        "visible":1,
                        "value":"test",
                        "sort":4
                    }
                ],
                "editable":1,
                "status":0,
                "url":""
            }
        ],
        "prePage":0,
        "nextPage":2,
        "isFirstPage":true,
        "isLastPage":false,
        "hasPreviousPage":false,
        "hasNextPage":true,
        "navigatePages":5,
        "navigatepageNums":Array[2],
        "navigateFirstPage":1,
        "navigateLastPage":2,
        "firstPage":1,
        "lastPage":2
    }
}
```

