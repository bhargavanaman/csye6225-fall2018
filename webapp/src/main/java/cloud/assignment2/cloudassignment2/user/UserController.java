package cloud.assignment2.cloudassignment2.user;

import java.util.Base64;
import java.util.Date;
import java.util.List;
import java.util.StringTokenizer;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import cloud.assignment2.cloudassignment2.Expense.ExpenseController;
import com.amazonaws.auth.InstanceProfileCredentialsProvider;
import com.amazonaws.services.cloudwatch.AmazonCloudWatch;
import com.amazonaws.services.cloudwatch.AmazonCloudWatchClientBuilder;
import com.amazonaws.services.cloudwatch.model.*;
import com.amazonaws.services.sns.AmazonSNS;
import com.amazonaws.services.sns.AmazonSNSAsyncClientBuilder;
import com.amazonaws.services.sns.model.PublishRequest;
import com.amazonaws.services.sns.model.Topic;
import com.timgroup.statsd.StatsDClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;


import com.google.gson.JsonObject;


@RestController
public class UserController {
	

	
	@Autowired
	private UserDao userdao;
	
	@Autowired
    private BCryptPasswordEncoder bCryptPasswordEncoder;

	@Autowired
	private UserRepository userRepo;

	@Autowired
	private StatsDClient statsDClient;

	private final static Logger logger= LoggerFactory.getLogger(ExpenseController.class);

	@RequestMapping(value="/hello")
	public String newfunc(){
		return "hii";
	}
	
	@RequestMapping(value="/user")
	public List<UserPojo> getAll()
	{
		statsDClient.incrementCounter("_GetAllUser_API_");
		logger.info("Inside_GetAllUser_API_");
		return userdao.getAll();
	}
	
	@RequestMapping(value="/")
	public String authUser(HttpServletRequest request, HttpServletResponse response) {

		statsDClient.incrementCounter("_UserLoggedinStatusCheck_API_");
		logger.info("Inside_UserLoggedinStatusCheck_API_");

		String authHeader = request.getHeader("Authorization");
		JsonObject jsonObject = new JsonObject();
		if(authHeader!=null)
		{
			authHeader = authHeader.replaceFirst("Basic ", "");
			String decodedString = new String(Base64.getDecoder().decode(authHeader.getBytes()));
			//jsonObject.addProperty("decodeString", decodedString);
			StringTokenizer itr = new StringTokenizer(decodedString, ":");
			String email = itr.nextToken();
			
			if(userdao.checkUser(email) == null)
			{
				jsonObject.addProperty("message", "The user doesnot exist.Try again!");
			}
			else
			{
				jsonObject.addProperty("message", "You are logged in. current time is " + new Date().toString());
			}
			
			return jsonObject.toString();
		}
		jsonObject.addProperty("message", "You are not logged in!");
		return jsonObject.toString();
	}
	
	
	
	@RequestMapping(value="/user/register" , method=RequestMethod.POST)
		public String addUser(@RequestBody UserPojo userpojo) {

		//statsDClient.incrementCounter("endpoint.homepage.http.post");
		statsDClient.incrementCounter("_RegisterUser_API_");
		logger.info("Inside_RegisterUser_API_");

		if((userdao.checkUser(userpojo.getEmail()) == null)){
			UserPojo up = new UserPojo();
			up.setId(userpojo.getId());
			up.setName(userpojo.getName());
			up.setEmail(userpojo.getEmail());
			up.setPassword(bCryptPasswordEncoder.encode(userpojo.getPassword()));
			userdao.addUser(up);
			
			JsonObject jsonObject = new JsonObject();
			jsonObject.addProperty("message", "User added successfully");
			return jsonObject.toString();
		}
		JsonObject jsonObject = new JsonObject();
		jsonObject.addProperty("message", "User already exists");
		return jsonObject.toString();
	}



	@RequestMapping(value="/user/resetPwd" , method=RequestMethod.POST)
	public String resetPassword(@RequestBody UserPojo userPojo){

		statsDClient.incrementCounter("_ResetPassword_API_");
		logger.info("Inside_ResetPassword_API_");
		JsonObject jsonObject = new JsonObject();
		String email = userPojo.getEmail();
		UserPojo up = userRepo.findUserPojoByEmail(email);
		if(up != null)
		{
			AmazonSNS snsClient = AmazonSNSAsyncClientBuilder.standard()
					.withCredentials(new InstanceProfileCredentialsProvider(false))
					.build();
			List<Topic> topics = snsClient.listTopics().getTopics();

			for(Topic topic: topics)
			{

				if(topic.getTopicArn().endsWith("SNSTopicResetPassword")){
					System.out.print(userPojo.getEmail());
					PublishRequest req = new PublishRequest(topic.getTopicArn(),userPojo.getEmail());
					snsClient.publish(req);
					break;
				}
			}
			jsonObject.addProperty("message","Successful");

		}
		else{
			jsonObject.addProperty("message","User not found");
		}
		return jsonObject.toString();
	}
	
}
