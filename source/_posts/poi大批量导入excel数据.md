title: poi大批量导入excel数据
# 1.2003 Reader
<!-- more -->
```
package com.tj.tjk.util.myExcel;  
  

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import org.apache.poi.hssf.eventusermodel.EventWorkbookBuilder.SheetRecordCollectingListener;
import org.apache.poi.hssf.eventusermodel.FormatTrackingHSSFListener;
import org.apache.poi.hssf.eventusermodel.HSSFEventFactory;
import org.apache.poi.hssf.eventusermodel.HSSFListener;
import org.apache.poi.hssf.eventusermodel.HSSFRequest;
import org.apache.poi.hssf.eventusermodel.MissingRecordAwareHSSFListener;
import org.apache.poi.hssf.eventusermodel.dummyrecord.LastCellOfRowDummyRecord;
import org.apache.poi.hssf.eventusermodel.dummyrecord.MissingCellDummyRecord;
import org.apache.poi.hssf.model.HSSFFormulaParser;
import org.apache.poi.hssf.record.BOFRecord;
import org.apache.poi.hssf.record.BlankRecord;
import org.apache.poi.hssf.record.BoolErrRecord;
import org.apache.poi.hssf.record.BoundSheetRecord;
import org.apache.poi.hssf.record.FormulaRecord;
import org.apache.poi.hssf.record.LabelRecord;
import org.apache.poi.hssf.record.LabelSSTRecord;
import org.apache.poi.hssf.record.NumberRecord;
import org.apache.poi.hssf.record.Record;
import org.apache.poi.hssf.record.SSTRecord;
import org.apache.poi.hssf.record.StringRecord;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.poifs.filesystem.POIFSFileSystem;
import org.springframework.web.multipart.MultipartFile;



/**
 * 名称: ExcelXlsReader.java<br>
 * 描述: <br>
 * 类型: JAVA<br>
 * 最近修改时间:2016年7月5日 上午10:00:32<br>
 * 
 * @since 2016年7月5日
 * @author “”
 */
public abstract class MyExcel2003Reader<T> implements HSSFListener {

    private int minColumns = -1;

    private POIFSFileSystem fs;

    private int lastRowNumber;

    private int lastColumnNumber;

    /** Should we output the formula, or the value it has? */
    private boolean outputFormulaValues = true;

    /** For parsing Formulas */
    private SheetRecordCollectingListener workbookBuildingListener;

    // excel2003工作薄
    private HSSFWorkbook stubWorkbook;

    // Records we pick up as we process
    private SSTRecord sstRecord;

    private FormatTrackingHSSFListener formatListener;

    // 表索引
    private int sheetIndex = -1;

    private BoundSheetRecord[] orderedBSRs;

    @SuppressWarnings("unchecked")
    private ArrayList boundSheetRecords = new ArrayList();

    // For handling formulas with string results
    private int nextRow;

    private int nextColumn;

    private boolean outputNextStringRecord;

    // 当前行
    private int curRow = 0;

    // 存储行记录的容器
    private List<String> rowlist = new ArrayList<String>();;

    @SuppressWarnings("unused")
    private String sheetName;


    /**
     * 遍历excel下所有的sheet
     * 
     * @throws IOException
     */
    public void process(String file) throws IOException {
        this.fs = new POIFSFileSystem(new FileInputStream(file));
        MissingRecordAwareHSSFListener listener = new MissingRecordAwareHSSFListener(this);
        formatListener = new FormatTrackingHSSFListener(listener);
        HSSFEventFactory factory = new HSSFEventFactory();
        HSSFRequest request = new HSSFRequest();
        if (outputFormulaValues) {
            request.addListenerForAllRecords(formatListener);
        } else {
            workbookBuildingListener = new SheetRecordCollectingListener(formatListener);
            request.addListenerForAllRecords(workbookBuildingListener);
        }
        factory.processWorkbookEvents(request, fs);
    }

    /**
     * HSSFListener 监听方法，处理 Record
     */
    @SuppressWarnings("unchecked")
    public void processRecord(Record record) {
        int thisRow = -1;
        int thisColumn = -1;
        String thisStr = null;
        String value = null;
        switch (record.getSid()) {
        case BoundSheetRecord.sid:
            boundSheetRecords.add(record);
            break;
        case BOFRecord.sid:
            BOFRecord br = (BOFRecord) record;
            if (br.getType() == BOFRecord.TYPE_WORKSHEET) {
                // 如果有需要，则建立子工作薄
                if (workbookBuildingListener != null && stubWorkbook == null) {
                    stubWorkbook = workbookBuildingListener.getStubHSSFWorkbook();
                }

                sheetIndex++;
                if (orderedBSRs == null) {
                    orderedBSRs = BoundSheetRecord.orderByBofPosition(boundSheetRecords);
                }
                sheetName = orderedBSRs[sheetIndex].getSheetname();
            }
            break;

        case SSTRecord.sid:
            sstRecord = (SSTRecord) record;
            break;

        case BlankRecord.sid:
            BlankRecord brec = (BlankRecord) record;
            thisRow = brec.getRow();
            thisColumn = brec.getColumn();
            thisStr = "";
            rowlist.add(thisColumn, thisStr);
            break;
        case BoolErrRecord.sid: // 单元格为布尔类型
            BoolErrRecord berec = (BoolErrRecord) record;
            thisRow = berec.getRow();
            thisColumn = berec.getColumn();
            thisStr = berec.getBooleanValue() + "";
            rowlist.add(thisColumn, thisStr);
            break;

        case FormulaRecord.sid: // 单元格为公式类型
            FormulaRecord frec = (FormulaRecord) record;
            thisRow = frec.getRow();
            thisColumn = frec.getColumn();
            if (outputFormulaValues) {
                if (Double.isNaN(frec.getValue())) {
                    // Formula result is a string
                    // This is stored in the next record
                    outputNextStringRecord = true;
                    nextRow = frec.getRow();
                    nextColumn = frec.getColumn();
                } else {
                    thisStr = formatListener.formatNumberDateCell(frec);
                }
            } else {
                thisStr = '"' + HSSFFormulaParser.toFormulaString(stubWorkbook, frec.getParsedExpression()) + '"';
            }
            rowlist.add(thisColumn, thisStr);
            break;
        case StringRecord.sid:// 单元格中公式的字符串
            if (outputNextStringRecord) {
                // String for formula
                StringRecord srec = (StringRecord) record;
                thisStr = srec.getString();
                thisRow = nextRow;
                thisColumn = nextColumn;
                outputNextStringRecord = false;
            }
            break;
        case LabelRecord.sid:
            LabelRecord lrec = (LabelRecord) record;
            curRow = thisRow = lrec.getRow();
            thisColumn = lrec.getColumn();
            value = lrec.getValue().trim();
            value = value.equals("") ? " " : value;
            this.rowlist.add(thisColumn, value);
            break;
        case LabelSSTRecord.sid: // 单元格为字符串类型
            LabelSSTRecord lsrec = (LabelSSTRecord) record;
            curRow = thisRow = lsrec.getRow();
            thisColumn = lsrec.getColumn();
            if (sstRecord == null) {
                rowlist.add(thisColumn, " ");
            } else {
                value = sstRecord.getString(lsrec.getSSTIndex()).toString().trim();
                value = value.equals("") ? " " : value;
                rowlist.add(thisColumn, value);
            }
            break;
        case NumberRecord.sid: // 单元格为数字类型
            NumberRecord numrec = (NumberRecord) record;
            curRow = thisRow = numrec.getRow();
            thisColumn = numrec.getColumn();
            value = formatListener.formatNumberDateCell(numrec).trim();
            value = value.equals("") ? " " : value;
            // 向容器加入列值
            rowlist.add(thisColumn, value);
            break;
        default:
            break;
        }

        // 遇到新行的操作
        if (thisRow != -1 && thisRow != lastRowNumber) {
            lastColumnNumber = -1;
        }

        // 空值的操作
        if (record instanceof MissingCellDummyRecord) {
            MissingCellDummyRecord mc = (MissingCellDummyRecord) record;
            curRow = thisRow = mc.getRow();
            thisColumn = mc.getColumn();
            rowlist.add(thisColumn, " ");
        }

        // 更新行和列的值
        if (thisRow > -1)
            lastRowNumber = thisRow;
        if (thisColumn > -1)
            lastColumnNumber = thisColumn;

        // 行结束时的操作
        if (record instanceof LastCellOfRowDummyRecord) {
        	 if (curRow == 0) {
        		 minColumns = lastColumnNumber;
             }
            if (minColumns > 0) {
                // 列值重新置空
                if (lastColumnNumber == -1) {
                    lastColumnNumber = 0;
                }
                for (int i = lastColumnNumber; i < minColumns; i++) {
            		rowlist.add("");
            		lastColumnNumber++;
            	}
            }
            lastColumnNumber = -1;

            // 每行结束时， 调用getRows() 方法
            getRows(sheetIndex, curRow, rowlist);
            // 清空容器
            rowlist.clear();
        }
    }
    /** 
     * 获取行数据回调 
     * @param sheetIndex 
     * @param curRow 
     * @param rowList 
     * @return 
     */ 
    public abstract void getRows(int sheetIndex, int curRow, List<String> rowList); 
    
      /*public static void main(String[] args) {
       IExcelRowReader rowReader = new ExcelRowReader();
      try {
          // ExcelReaderUtil.readExcel(rowReader,
          // "E://2016-07-04-011940a.xls");
            System.out.println("**********************************************");
            ExcelReaderUtil.readExcel(rowReader, "E://test.xlsx");
            } catch (Exception e) {
            e.printStackTrace();
           }
       }*/


}
```
# 2. 2007 Reader
```
package com.tj.tjk.util.myExcel;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import org.apache.commons.lang.StringUtils;
import org.apache.poi.openxml4j.exceptions.OpenXML4JException;
import org.apache.poi.openxml4j.opc.OPCPackage;
import org.apache.poi.ss.usermodel.BuiltinFormats;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.xssf.eventusermodel.XSSFReader;
import org.apache.poi.xssf.model.SharedStringsTable;
import org.apache.poi.xssf.model.StylesTable;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFRichTextString;
import org.xml.sax.Attributes;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.XMLReader;
import org.xml.sax.helpers.DefaultHandler;
import org.xml.sax.helpers.XMLReaderFactory;


/**
 * 名称: ExcelXlsxReader.java<br>
 * 描述: <br>
 * 类型: JAVA<br>
 * 最近修改时间:2016年7月5日 上午10:00:52<br>
 * 
 * @since 2016年7月5日
 * @author “”
 */
public abstract class MyExcel2007Reader<T> extends DefaultHandler {


    /**
     * 共享字符串表
     */
    private SharedStringsTable sst;

    /**
     * 上一次的内容
     */
    private String lastContents;

    /**
     * 字符串标识
     */
    private boolean nextIsString;

    /**
     * 工作表索引
     */
    private int sheetIndex = -1;

    /**
     * 行集合
     */
    private List<String> rowlist = new ArrayList<String>();

    /**
     * 当前行
     */
    private int curRow = 0;

    /**
     * 当前列
     */
    private int curCol = 0;

    /**
     * T元素标识
     */
    private boolean isTElement;

    /**
     * 单元格数据类型，默认为字符串类型
     */
    private CellDataType nextDataType = CellDataType.SSTINDEX;

    private final DataFormatter formatter = new DataFormatter();

    private short formatIndex;

    private String formatString;

    // 定义前一个元素和当前元素的位置，用来计算其中空的单元格数量，如A6和A8等
    private String ref = null;

    // 定义该文档一行最大的单元格数，用来补全一行最后可能缺失的单元格
    private String maxRef = null;
    
 // 定义当前读到的列数，实际读取时会按照从0开始...
    private int thisColumn = -1;
    //一行最大列数
    private int maxClumn;
    // 定义上一次读到的列序号
    private int lastColumnNumber = -1;
 // 定义当前读到的列与上一次读到的列中是否有空值（即该单元格什么也没有输入，连空格都不存在）默认为false
    private boolean flag = false ;
    
    /**
     * 单元格
     */
    private StylesTable stylesTable;
    

    /**
     * 遍历工作簿中所有的电子表格
     * 
     * @param filename
     * @throws IOException
     * @throws OpenXML4JException
     * @throws SAXException
     * @throws Exception
     */
    public void process(String name) throws IOException, OpenXML4JException, SAXException {
        OPCPackage pkg = OPCPackage.open(name);
        XSSFReader xssfReader = new XSSFReader(pkg);
        stylesTable = xssfReader.getStylesTable();
        SharedStringsTable sst = xssfReader.getSharedStringsTable();
        XMLReader parser = this.fetchSheetParser(sst);
        Iterator<InputStream> sheets = xssfReader.getSheetsData();
        while (sheets.hasNext()) {
            curRow = 0;
            sheetIndex++;
            InputStream sheet = sheets.next();
            InputSource sheetSource = new InputSource(sheet);
            parser.parse(sheetSource);
            sheet.close();
        }
        pkg.close();
    }

    public XMLReader fetchSheetParser(SharedStringsTable sst) throws SAXException {
        XMLReader parser = XMLReaderFactory.createXMLReader("org.apache.xerces.parsers.SAXParser");
        this.sst = sst;
        parser.setContentHandler(this);
        return parser;
    }

    /**
     * Converts an Excel column name like "C" to a zero-based index.
     *
     * @param name
     * @return Index corresponding to the specified name
     */
    private int nameToColumn(String name) {
        int column = -1;
        for (int i = 0; i < name.length(); ++i) {
            int c = name.charAt(i);
            column = (column + 1) * 26 + c - 'A';
        }
        return column;
    }
    
    public void startElement(String uri, String localName, String name, Attributes attributes) throws SAXException {
//    	if ("inlineStr".equals(name) || "v".equals(name)) {
//            vIsOpen = true;
//            // Clear contents cache
//            value.setLength(0);
//        }
        // c => cell
    	if ("c".equals(name)) {
            // Get the cell reference
            String r = attributes.getValue("r");
            int firstDigit = -1;
            for (int c = 0; c < r.length(); ++c) {
                if (Character.isDigit(r.charAt(c))) {
                    firstDigit = c;
                    break;
                }
            }
            thisColumn = nameToColumn(r.substring(0, firstDigit));//获取当前读取的列数
//        // c => 单元格
//        if ("c".equals(name)) {
//            // 前一个单元格的位置
//            if (preRef == null) {
//                preRef = attributes.getValue("r");
//            } else {
//                preRef = ref;
//            }
            // 当前单元格的位置
            ref = attributes.getValue("r");
            // 设定单元格类型
            this.setNextDataType(attributes);
            // Figure out if the value is an index in the SST
            String cellType = attributes.getValue("t");
            if (cellType != null && cellType.equals("s")) {
                nextIsString = true;
            } else {
                nextIsString = false;
            }
        }

        // 当元素为t时
        if ("t".equals(name)) {
            isTElement = true;
        } else {
            isTElement = false;
        }

        // 置空
        lastContents = "";
    }

    /**
     * 单元格中的数据可能的数据类型
     */
    enum CellDataType {
        BOOL, ERROR, FORMULA, INLINESTR, SSTINDEX, NUMBER, DATE, NULL
    }

    /**
     * 处理数据类型
     * 
     * @param attributes
     */
    public void setNextDataType(Attributes attributes) {
        nextDataType = CellDataType.NUMBER;
        formatIndex = -1;
        formatString = null;
        String cellType = attributes.getValue("t");
        String cellStyleStr = attributes.getValue("s");

        if ("b".equals(cellType)) {
            nextDataType = CellDataType.BOOL;
        } else if ("e".equals(cellType)) {
            nextDataType = CellDataType.ERROR;
        } else if ("inlineStr".equals(cellType)) {
            nextDataType = CellDataType.INLINESTR;
        } else if ("s".equals(cellType)) {
            nextDataType = CellDataType.SSTINDEX;
        } else if ("str".equals(cellType)) {
            nextDataType = CellDataType.FORMULA;
        }

        if (cellStyleStr != null) {
            int styleIndex = Integer.parseInt(cellStyleStr);
            XSSFCellStyle style = stylesTable.getStyleAt(styleIndex);
            formatIndex = style.getDataFormat();
            formatString = style.getDataFormatString();

            if ("m/d/yy" == formatString) {
                nextDataType = CellDataType.DATE;
                formatString = "yyyy-MM-dd hh:mm:ss.SSS";
            }

            if (formatString == null) {
                nextDataType = CellDataType.NULL;
                formatString = BuiltinFormats.getBuiltinFormat(formatIndex);
            }
        }
    }

    /**
     * 对解析出来的数据进行类型处理
     * 
     * @param value
     *            单元格的值（这时候是一串数字）
     * @param thisStr
     *            一个空字符串
     * @return
     */
    public String getDataValue(String value, String thisStr) {
        switch (nextDataType) {
        // 这几个的顺序不能随便交换，交换了很可能会导致数据错误
        case BOOL:
            char first = value.charAt(0);
            thisStr = first == '0' ? "FALSE" : "TRUE";
            break;
        case ERROR:
            thisStr = "\"ERROR:" + value.toString() + '"';
            break;
        case FORMULA:
            thisStr = '"' + value.toString() + '"';
            break;
        case INLINESTR:
            XSSFRichTextString rtsi = new XSSFRichTextString(value.toString());

            thisStr = rtsi.toString();
            rtsi = null;
            break;
        case SSTINDEX:
            String sstIndex = value.toString();
            try {
                int idx = Integer.parseInt(sstIndex);
                XSSFRichTextString rtss = new XSSFRichTextString(sst.getEntryAt(idx));
                thisStr = rtss.toString();
                rtss = null;
            } catch (NumberFormatException ex) {
                thisStr = value.toString();
            }
            break;
        case NUMBER:
            if (formatString != null) {
                thisStr = formatter.formatRawCellContents(Double.parseDouble(value), formatIndex, formatString).trim();
            } else {
                thisStr = value;
            }

            thisStr = thisStr.replace("_", "").trim();
            break;
        case DATE:
            thisStr = formatter.formatRawCellContents(Double.parseDouble(value), formatIndex, formatString);

            // 对日期字符串作特殊处理
            thisStr = thisStr.replace(" ", "T");
            break;
        default:
            thisStr = " ";

            break;
        }

        return thisStr;
    }

    @Override
    public void endElement(String uri, String localName, String name) throws SAXException {
        // 根据SST的索引值的到单元格的真正要存储的字符串
        // 这时characters()方法可能会被调用多次
        if (nextIsString  &&  StringUtils.isNotEmpty(lastContents) && StringUtils.isNumeric(lastContents)) {
            int idx = Integer.parseInt(lastContents);
            lastContents = new XSSFRichTextString(sst.getEntryAt(idx)).toString();
        }

        // t元素也包含字符串
        if (isTElement) {
            // 将单元格内容加入rowlist中，在这之前先去掉字符串前后的空白符
            String value = lastContents.trim();
            rowlist.add(curCol, value);
            curCol++;
            isTElement = false;
        } else if ("v".equals(name)) {
            // v => 单元格的值，如果单元格是字符串则v标签的值为该字符串在SST中的索引
            String value = this.getDataValue(lastContents.trim(), "");
            // 补全单元格之间的空单元格
//            if (!ref.equals(preRef)) {
//                int len = countNullCell(ref, preRef);
//                for (int i = 0; i < len; i++) {
//                    rowlist.add(curCol, "");
//                    curCol++;
//                }
//            }
//            rowlist.add(curCol, value);
//            curCol++;
         // 以下是核心算法，在同一行内，若后一次比前一次读取的列序号相差大于1，证明中间没有读到值
            // 按照.xlsx底层是xml描述文件原理，此时对应xml中"空值"情况
            if(thisColumn - lastColumnNumber > 1){
                flag = true ;
            }
            for (int i = lastColumnNumber; i < thisColumn; ++i){
                if(flag && i > lastColumnNumber){
                    rowlist.add(i, "");
                }
            }

            // Might be the empty string.
            rowlist.add(thisColumn, value);

            // Update column
            if (thisColumn > -1){
                lastColumnNumber = thisColumn;
            }
                
        } else {
            // 如果标签名称为 row ，这说明已到行尾，调用 optRows() 方法
            if (name.equals("row")) {
                // 默认第一行为表头，以该行单元格数目为最大数目
                if (curRow == 0) {
                    maxRef = ref;
                    int firstDigit = -1;
                    for (int c = 0; c < maxRef.length(); ++c) {
                        if (Character.isDigit(maxRef.charAt(c))) {
                            firstDigit = c;
                            break;
                        }
                    }
                  maxClumn = nameToColumn(maxRef.substring(0, firstDigit));
                }
                // 补全一行尾部可能缺失的单元格
                if (maxRef != null) {
                	if (lastColumnNumber == -1) {
                		   lastColumnNumber = 0;
                	}
                	
                	for (int i = lastColumnNumber; i < maxClumn; i++) {
                		rowlist.add("");
                		lastColumnNumber++;
                	}
//                    int len = countNullCell(maxRef, ref);
//                    
//                    for (int i = 0; i <= len; i++) {
//                    	rowlist.add(thisColumn+1, "");
//                        thisColumn++;
//                    }
                }
                getRows(sheetIndex, curRow, rowlist);
                rowlist.clear();
                curRow++;
                flag = false ;
                // We're onto a new row
                lastColumnNumber = -1;
                thisColumn = 0;
                ref = null;
            }
        }
    }

    /**
     * 计算两个单元格之间的单元格数目(同一行)
     * 
     * @param ref
     * @param preRef
     * @return
     */
    public int countNullCell(String ref, String preRef) {
        // excel2007最大行数是1048576，最大列数是16384，最后一列列名是XFD
        String xfd = ref.replaceAll("\\d+", "");
        String xfd_1 = preRef.replaceAll("\\d+", "");

        xfd = fillChar(xfd, 3, '@', true);
        xfd_1 = fillChar(xfd_1, 3, '@', true);

        char[] letter = xfd.toCharArray();
        char[] letter_1 = xfd_1.toCharArray();
        int res = (letter[0] - letter_1[0]) * 26 * 26 + (letter[1] - letter_1[1]) * 26 + (letter[2] - letter_1[2]);
        return res - 1;
    }

    /**
     * 字符串的填充
     * 
     * @param str
     * @param len
     * @param let
     * @param isPre
     * @return
     */
    String fillChar(String str, int len, char let, boolean isPre) {
        int len_1 = str.length();
        if (len_1 < len) {
            if (isPre) {
                for (int i = 0; i < (len - len_1); i++) {
                    str = let + str;
                }
            } else {
                for (int i = 0; i < (len - len_1); i++) {
                    str = str + let;
                }
            }
        }
        return str;
    }

    @Override
    public void characters(char[] ch, int start, int length) throws SAXException {
        // 得到单元格内容的值
        lastContents += new String(ch, start, length);
    }

    /** 
     * 获取行数据回调 
     * @param sheetIndex 
     * @param curRow 
     * @param rowList 
     */ 
	public abstract void getRows(int sheetIndex, int curRow, List<String> rowList);
	
}

```