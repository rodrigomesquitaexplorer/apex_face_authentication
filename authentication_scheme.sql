PROCEDURE POST_LOGIN
IS
BEGIN
APEX_CUSTOM_AUTH.SET_USER(:USER_DATA);
END;

FUNCTION AUTHENTICATE_USER
  (p_username in varchar2, 
   p_password in varchar2)
return boolean
is
    l_clob       CLOB;
    l_body       clob;
    l_paths      APEX_T_VARCHAR2;
    l_person_id  VARCHAR2(1000);
begin
--
    apex_web_service.g_request_headers(1).name := 'Ocp-Apim-Subscription-Key';  
    apex_web_service.g_request_headers(1).value := '<add the API KEY here>';
    apex_web_service.g_request_headers(2).name := 'Content-Type';  
    apex_web_service.g_request_headers(2).value := 'application/json';

    APEX_JSON.initialize_clob_output;
    APEX_JSON.open_object;
    APEX_JSON.write('PersonGroupId', 'users');
    APEX_JSON.open_array('faceIds');   
    APEX_JSON.write(:P9999_FACE_ID);
    APEX_JSON.close_array; 
    APEX_JSON.write('maxNumOfCandidatesReturned', '1');
    APEX_JSON.write('confidenceThreshold', '0.5');
    APEX_JSON.close_object;
    l_body := APEX_JSON.get_clob_output;
    APEX_JSON.free_output;
      
     l_clob := apex_web_service.make_rest_request(
             p_url => 'https://northeurope.api.cognitive.microsoft.com/face/v1.0/identify',
             p_http_method => 'POST',
             p_body => l_body);
    
           l_clob := replace(replace(l_clob,']',''),'[','');
           APEX_JSON.parse(l_clob);
           l_paths := APEX_JSON.find_paths_like (p_return_path => 'candidates');
            
            FOR i IN 1 .. l_paths.COUNT loop
              l_person_id := APEX_JSON.get_varchar2(p_path => l_paths(i)||'.personId'); 
            END LOOP;   
          IF l_person_id IS NOT NULL 
          THEN
          l_clob := apex_web_service.make_rest_request(
                 p_url => 'https://northeurope.api.cognitive.microsoft.com/face/v1.0/persongroups/users/persons/'||l_person_id,
                 p_http_method => 'GET',
                 p_body => '{body}');   
           APEX_JSON.parse(l_clob);
           APEX_UTIL.SET_AUTHENTICATION_RESULT(0);
           
           :USER_DATA := APEX_JSON.get_varchar2(p_path => 'userData');
           :NAME      := APEX_JSON.get_varchar2(p_path => 'name');
              return true;
          ELSE
            -- The Person didn't match
            APEX_UTIL.SET_AUTHENTICATION_RESULT(1);
          return false;
          END IF;

exception 
    when others then 
        APEX_UTIL.SET_AUTHENTICATION_RESULT(7);
        APEX_UTIL.SET_CUSTOM_AUTH_STATUS('A Face authentication error has occured, Please try again');
        return false;
        
end authenticate_user;
