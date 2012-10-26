public class Coaching_Report_ext {
    Id coachingReportId = ApexPages.currentPage().getParameters().get('id');
    public Coaching_Report_vod__c coachingReport = null;
    
    public Coaching_Report_ext(ApexPages.StandardController controller) {
        if(coachingReportId == null) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Constructor: id is null.');
            ApexPages.AddMessage(myMsg);
            system.debug('Constructor: checklist id is null');
            return;
        }
        coachingReport = [Select Id,Manager_vod__c,Employee_vod__c, OwnerId, Status__c from Coaching_Report_vod__c where Id = :coachingReportId];
    }
        
    public PageReference submitMe() {
        if(coachingReportId == null) {
            system.debug('submitMe: checklist id is null');
            return null;
        }
        
        if(coachingReport.Status__c != 'In Progress') {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'This checklist has already been submitted. Current Status: ' + coachingReport.Status__c);
            ApexPages.AddMessage(myMsg);
            return null;
        }
        
        PageReference returnRef = null;
        
        String currentUserId = UserInfo.getUserId();
        if(currentUserId == coachingReport.Manager_vod__c) {
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting Coaching Report for acknowledgement');
            req1.setObjectId(coachingReportId);
            Approval.ProcessResult result = Approval.process(req1);
            System.assert(result.isSuccess());
            
            Coaching_Report_vod__Share crs = new Coaching_Report_vod__Share();
            crs.UserOrGroupId = coachingReport.Employee_vod__c;
            crs.ParentId = coachingReportId;
            crs.AccessLevel = 'Read';
            insert crs;
                        
            returnRef = new PageReference('/' + coachingReport.Id);
            returnRef.setRedirect(true);
        }
        else {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Only the rating Manager may submit a Coaching Report.');
            ApexPages.AddMessage(myMsg);
            returnRef = null;
        }
        
        return returnRef;
    }
    
    public PageReference acknowledgeMe() {
        if(coachingReportId == null) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'AcknowledgeMe: id is null.');
            ApexPages.AddMessage(myMsg);
            system.debug('acknowledgeMe: checklist id is null');
            return null;
        }
        
        if(coachingReport.Status__c != 'Pending Acknowledgement') {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'This Coaching Report is not pending acknowledgement.');
            ApexPages.AddMessage(myMsg);
            return null;
        }
        
        PageReference returnRef = null;
        
        String currentUserId = UserInfo.getUserId();
        if(currentUserId == coachingReport.Employee_vod__c) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'AcknowledgeMe: In main processing.');
            ApexPages.AddMessage(myMsg);
            // Instantiate the new ProcessWorkitemRequest object and populate it
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Acknowledging request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            
            ProcessInstance p = [Select Id, TargetObjectId from ProcessInstance where TargetObjectId = :coachingReportId Limit 1];
            ProcessInstanceWorkItem pw = [Select Id, ProcessInstanceId from ProcessInstanceWorkItem where ProcessInstanceId = :p.Id Limit 1];
            req2.setWorkitemId(pw.Id);
            
            Approval.ProcessResult result2 = Approval.process(req2);
            
            System.assert(result2.isSuccess());
            
            returnRef = new PageReference('/' + coachingReport.Id);
            returnRef.setRedirect(true);
        }
        else {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Only the rated employee may acknowledge Coaching Report.');
            ApexPages.AddMessage(myMsg);
            returnRef = null;
        }
        
        return returnRef;
    }    
}