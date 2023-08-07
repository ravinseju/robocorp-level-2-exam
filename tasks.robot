*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...    
Library    RPA.Browser.Selenium    auto_close=${FALSE}    implicit_wait=30 seconds
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive

*** Variables ***
${ORDER_URL}=                   https://robotsparebinindustries.com/#/robot-order
${FILE_URL}=                    https://robotsparebinindustries.com/orders.csv
${GLOBAL_RETRY_AMOUNT}=         3x
${GLOBAL_RETRY_INTERVAL}=       0.5s

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the Orders file
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Log    Processing order ${row}[Order number]
        Close the annoying modal
        Fill the form    ${row}
        ${screenshot}=    Take a screenshot of the order    ${row}[Order number]
        Wait Until Keyword Succeeds
        ...    ${GLOBAL_RETRY_AMOUNT}
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Submit Robot Order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click Button When Visible    locator=id:order-another
    END
    Archive receipts
    [Teardown]    Close the browser

*** Keywords ***
Open the robot order website
    Open Available Browser    ${ORDER_URL}

Download the Orders file
    Download    ${FILE_URL}    overwrite=True

Get orders
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://input[@type="number"]    ${order}[Legs]
    Input Text    address    ${order}[Address]

Take a screenshot of the order
    [Arguments]    ${order_num}
    Click Button    Preview
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}${order_num}-robot-preview.png
    RETURN    ${OUTPUT_DIR}${/}${order_num}-robot-preview.png

Submit Robot Order
    Click Button    Order
    Page Should Contain Element    locator=id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order_num}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}${order_num}-robot-receipt.pdf
    RETURN    ${OUTPUT_DIR}${/}${order_num}-robot-receipt.pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}

Archive receipts
    Archive Folder With Zip
    ...    folder=${OUTPUT_DIR}
    ...    archive_name=robot_orders.zip
    ...    include=*.pdf
    
Close the browser
    Close Browser