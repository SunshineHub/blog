---
title: 导出CSV文档demo
date: 2017-7-28 08:30:00
cover: /images/git入门/20180929065330555.png
subtitle: java实现csv导出模式。
author: 
  name: WangCh
  link: https://github.com/SunshineHub
tags:
 - java 
 - csv 
categories:
 - csv
---
# 绪论
相信大家对于后台导出数据到excel表的需求很熟悉的。最近在开发项目过程中，就有用户的导入导出功能。开始我思路是用户导出导入都使用excel格式，但是到后面发现，其实在导出大量数据的时候，excel表是有很大局性的。一次导出10W条数据的时候，发现导出为excel失败，查看错误信息就是excel表对于数据的行数有限制，excel2003是65535条，excel2007会更多(还是会有限制)。考虑到管理员电脑的excel版本有高有低（必须兼容最低版本03），加上导出这么多数据，内存占用会比较大，弄不好会出现内存泄漏。随着用户量的不断增加，导出为excel显得越来不可取。于是就采用导出为csv格式，加上csv可以使用excel表打开，这看来是不错的做法。
## 什么是CSV
那什么是csv？格式又是怎么样的呢？
CSV：逗号分隔值（Comma-Separated Values，CSV，有时也称为字符分隔值，因为分隔字符也可以不是逗号），
其文件以纯文本形式存储表格数据（数字和文本）。纯文本意味着该文件是一个字符序列，不含必须像二进制数
字那样被解读的数据。CSV文件由任意数目的记录组成，记录间以某种换行符分隔；每条记录由字段组成，字段
间的分隔符是其它字符或字符串，最常见的是逗号或制表符。通常，所有记录都有完全相同的字段序列。通常都
是纯文本文件。
给大家举例子：

    用户昵称,用户账号,用户等级  
    圣诞老人1,13800138000,VIP7  
    圣诞老人2,13800138000,VIP7  
    圣诞老人3,13800138000,VIP8
代码实现
源码
这里结合代码给大家讲解一下一个具体demo的实现，不需要依赖任何jar。

```
@RequestMapping("monitorCustomerTeamSpeechExport")
public void monitorCustomerTeamSpeechExport(HttpServletResponse response, Model model,CallHistoryQuery query){
	try {
		if (query.getCallDurationMin()!=null) {
			query.setCallDurationMin((query.getCallDurationMin())*60);
		}
		if (query.getCallDurationMax()!=null) {
			query.setCallDurationMax((query.getCallDurationMax())*60);
		}
		query.setIsExport(1);
		query.setPerItems(1);
		query.setCurrPage(1);
		query.setOrderBy("time_from DESC");
		query.initPagination();
		
		com.tj.plateform.base.call.Pagination<CallHistory> queryCallHistory = callHistoryService.queryCallHistory(query);
		int totalRecord = queryCallHistory.getTotalRecord();
		if (totalRecord>60000) {
			totalRecord=60000;
		}
		int currPage = 1;
		int pageSize=5000;
		int totalPage = (totalRecord + pageSize -1) / pageSize;
		String title= "日期,开始时间,结束时间,耗时,客服名称,客户,操作类型,单价,费用,商家名称,商家电话,录音地址\n";
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		baos.write(239);   // 0xEF  
		baos.write(187);   // 0xBB  
		baos.write(191);
		BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(baos,"UTF-8"));
		bw.write(title);
		query.setPerItems(pageSize);
		long forstart = System.currentTimeMillis();
		for(; currPage<=totalPage; currPage++) {
			query.setCurrPage(currPage);
			query.initPagination();
			long startQuery = System.currentTimeMillis();
			queryCallHistory = callHistoryService.queryCallHistory(query);
			long endQuery = System.currentTimeMillis();
			System.out.println("-------------------查询需要时间： "+(endQuery-startQuery)+"--------------------");
			if (queryCallHistory.getList() != null) {
				long startimport = System.currentTimeMillis();
				exportCSV(bw,queryCallHistory.getList());
				long endImport = System.currentTimeMillis();
				System.out.println("-------------------写入2000条需要时间： "+(endImport-startimport)+"--------------------");
			}
		}
		long endFor = System.currentTimeMillis();
		System.out.println("-------------------for循环需要时间： "+(endFor-forstart)+"--------------------");
		bw.flush();
		byte[] data = baos.toByteArray();
		String fileName = "export_"+DateUtil.getCurrDateTime("yyyy-MM-dd");
		response.setHeader("Content-disposition", "attachment; filename="
				+ fileName + ".csv");// 设定输出文件头
		response.setContentType("application/csv");// 定义输出类型
		response.getOutputStream().write(data, 0, data.length);
		bw.close();
	} catch (Exception e) {
		logger.error("导出异常", e);
	}
}

public void exportCSV(BufferedWriter bw, List<CallHistory> data) throws IOException{
	for (CallHistory mminfo : data) {
		StringBuffer sb = new StringBuffer();
		sb.append(DateUtil.converDate2Str(mminfo.getTimeFrom(), "yyyy-MM-dd")+",");
		sb.append(DateUtil.converDate2Str(mminfo.getTimeFrom(), "HH:mm:ss")+",");
		sb.append(DateUtil.converDate2Str(mminfo.getTimeTo(), "HH:mm:ss")+",");
		sb.append(secondByminute(mminfo.getInteval())+",");
		sb.append(mminfo.getAgentName()+",");
		sb.append( "0".equals(mminfo.getCallType()) ? mminfo.getCaller()+"," : mminfo.getCalled()+",");
		sb.append( "0".equals(mminfo.getCallType()) ? "接听," : "外呼,");
		if(mminfo.getPrice() == null) {
			sb.append("￥0.00/min,");
		} else {
			Double prices = mminfo.getPrice().doubleValue()/100.0;
			sb.append("￥"+replaceAllZero(prices.toString())+"/min,");
		}
		if(mminfo.getFee() == null) {
			sb.append("￥0.00/min,");
		} else {
			Double fees = mminfo.getFee().doubleValue()/100.0;
			sb.append("￥"+replaceAllZero(fees.toString())+"/min,");
		}
		sb.append(mminfo.getTitle()+",");
		sb.append(mminfo.getPhoneNumber()+",");
		sb.append(mminfo.getRecordUrl()+"\n");
		bw.write(sb.toString());
	}
}
```