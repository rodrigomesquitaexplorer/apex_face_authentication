DECLARE
    l_clob        CLOB;
    l_body        CLOB;
    lv_group_id   VARCHAR2(100) := 'users'; 
    lv_person_id  VARCHAR2(100); 
    l_image       BLOB;
BEGIN
    apex_web_service.g_request_headers(1).name := 'Ocp-Apim-Subscription-Key';  
    apex_web_service.g_request_headers(1).value := '<add the API KEY here>';
    apex_web_service.g_request_headers(2).name := 'Content-Type';  
    apex_web_service.g_request_headers(2).value := 'application/json';

--	Create a Person Group: Create a new person group passing JSON with specified personGroupId, name, user-provided userData and recognitionModel.
    APEX_JSON.initialize_clob_output;
    APEX_JSON.open_object;
    APEX_JSON.write('name', lv_group_id);
    APEX_JSON.write('userData', 'user-provided data attached to the person group.');
    APEX_JSON.write('recognitionModel', 'recognition_03');
    APEX_JSON.close_object;
    l_body := APEX_JSON.get_clob_output;
    APEX_JSON.free_output;
    
    l_clob := apex_web_service.make_rest_request(
        p_url => 'https://northeurope.api.cognitive.microsoft.com/face/v1.0/persongroups/'||lv_group_id,
        p_http_method => 'PUT',
        p_body => l_body);

--Create a Person in the group
    APEX_JSON.initialize_clob_output;
    APEX_JSON.open_object;
    APEX_JSON.write('name', 'Rodrigo');
    APEX_JSON.write('userData', 'RODRIGOM');
    APEX_JSON.close_object;
    l_body := APEX_JSON.get_clob_output;
    APEX_JSON.free_output;

    l_clob := apex_web_service.make_rest_request(
        p_url => 'https://northeurope.api.cognitive.microsoft.com/face/v1.0/persongroups/'||lv_group_id||'/persons',
        p_http_method => 'POST',
        p_body => l_body);
         
     APEX_JSON.parse(l_clob);
     lv_person_id := APEX_JSON.get_varchar2(p_path => 'personId');

--Add a face to the person: Each person entry can hold up to 248 faces. 

        -- get user image
        SELECT IMAGE
          INTO l_image
          FROM USER_IMAGES
         WHERE USER_ID = 'RODRIGOM';
     apex_web_service.g_request_headers.delete(2);
     apex_web_service.g_request_headers(2).name := 'Content-Type';  
     apex_web_service.g_request_headers(2).value := 'application/octet-stream'; 
     
     l_clob := apex_web_service.make_rest_request(
        p_url => 'https://northeurope.api.cognitive.microsoft.com/face/v1.0/persongroups/'||lv_group_id||'/persons/'||lv_person_id||'/persistedFaces?detectionModel=detection_01',
        p_http_method => 'POST',
        p_body_blob => l_image);

--Train the Group: This call submits a person group training task. Training is a crucial step as only a trained person group can be used. Each time we create or change a group, a face or a person from a group, then that group should be trained again

      apex_web_service.g_request_headers.delete(2);

     l_clob := apex_web_service.make_rest_request(
        p_url => 'https://northeurope.api.cognitive.microsoft.com/face/v1.0/persongroups/'||lv_group_id||'/training',
        p_http_method => 'POST',
        p_body => '{body}');      

END;
