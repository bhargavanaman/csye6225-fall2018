package cloud.assignment2.cloudassignment2.Receipt;

import cloud.assignment2.cloudassignment2.Expense.ExpensePojo;
import cloud.assignment2.cloudassignment2.Expense.ExpenseRepository;
import cloud.assignment2.cloudassignment2.user.UserDao;
import com.amazonaws.AmazonServiceException;
import com.amazonaws.SdkClientException;
import com.amazonaws.auth.profile.ProfileCredentialsProvider;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import com.amazonaws.services.s3.model.CannedAccessControlList;
import com.amazonaws.services.s3.model.PutObjectRequest;
import com.amazonaws.services.s3.transfer.TransferManager;
import com.amazonaws.services.s3.transfer.TransferManagerBuilder;
import com.amazonaws.services.s3.transfer.Upload;
import com.google.gson.JsonObject;
import org.apache.catalina.servlet4preview.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.servlet.http.HttpServletResponse;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@RestController
@Configuration
@Profile("dev")
public class ReceiptControllerDev {

    @Autowired
    UserDao userDao;

    @Autowired
    ExpenseRepository expenseRepository;

    @Autowired
    ReceiptRepository receiptRepository;

    String clientRegion = "us-east-1";
    String bucketName = "csye6225-fall2018-chandwanid.me.csye6225.com";

    @RequestMapping(value="/transaction/{id}/attachments" , method = RequestMethod.POST)
    public String uploadReceipt(@PathVariable(value="id") String transactionId, @RequestParam("file") MultipartFile file, HttpServletRequest req,
                                HttpServletResponse res){

        System.out.println("DEV Environment");
        JsonObject json = new JsonObject();

        String fileName = file.getOriginalFilename();
        String header = req.getHeader("Authorization");
        if(header != null) {
            int result = userDao.authUserCheck(header);
            if(result>0)
            {
                List<ExpensePojo> expensePojoRecord = expenseRepository.findAllById(transactionId);
                if(expensePojoRecord.size()>0){
                    ExpensePojo expenseRecord = expensePojoRecord.get(0);
                    if(Integer.parseInt(expenseRecord.getUserId()) == result)
                    {
                        // Upload to Amazon S3 Start
                        try {
                            AmazonS3 s3Client = AmazonS3ClientBuilder.standard()
                                    .withRegion(clientRegion)
                                    .withCredentials(new ProfileCredentialsProvider())
                                    .build();

                            s3Client.putObject(new PutObjectRequest(bucketName, fileName,
                                    new File("/home/deepakchandwani/Downloads/"+file.getOriginalFilename()))
                                    .withCannedAcl(CannedAccessControlList.PublicRead));

                        }
                        catch(AmazonServiceException e) {
                            // The call was transmitted successfully, but Amazon S3 couldn't process
                            // it, so it returned an error response.
                            e.printStackTrace();
                        }
                        catch(SdkClientException e) {
                            // Amazon S3 couldn't be contacted for a response, or the client
                            // couldn't parse the response from Amazon S3.
                            e.printStackTrace();
                        }
                        // Upload to Amazon S3 End




                        ReceiptPojo receiptPojo = new ReceiptPojo();
                        receiptPojo.setTransactionId(transactionId);
                        receiptPojo.setUrl(fileName);
                        receiptPojo.setUserId(String.valueOf(result));
                        receiptRepository.save(receiptPojo);
                        res.setStatus(HttpServletResponse.SC_OK);
                        json.addProperty("message","File uploaded");
                    }
                    else{
                        res.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                        json.addProperty("message","You are unauthorized. UserId do not match");
                    }

                }
                else{
                    res.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    json.addProperty("message","Bad Request! No id found");
                }
            }
            else{
                res.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                json.addProperty("message","You are unauthorized");
            }

        }else{
            res.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            json.addProperty("message","You are unauthorized");
        }
        return json.toString();

    }
    
}

