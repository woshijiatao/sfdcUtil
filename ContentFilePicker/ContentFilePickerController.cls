public with sharing class ContentFilePickerController {
    @AuraEnabled
    public static List<File> getRecentlyFiles() {
        Map<Id, RecentlyViewed> RecentlyViewedFileMapping = new Map<Id, RecentlyViewed>([
            SELECT Id
            FROM RecentlyViewed
            WHERE Type = 'ContentDocument'
            ORDER BY LastViewedDate DESC
            LIMIT 20
        ]);

        List<File> recentlyViewdFiles = new List<File>();
        for(ContentDocument document : [
            SELECT Id, Title, ContentSize, FileType, FileExtension, LastModifiedDate
            FROM ContentDocument
            WHERE Id IN :RecentlyViewedFileMapping.keySet()
        ]) {
            recentlyViewdFiles.add(
                new File(document)
            );
        }

        return recentlyViewdFiles;
    }

    @AuraEnabled
    public static List<File> getFilesOwnedByMe(){
        List<File> FilesOwnedByMe = new List<File>();
        for(ContentDocument document : [
            SELECT Id, Title, ContentSize, FileType, FileExtension, LastModifiedDate
            FROM ContentDocument
            WHERE OwnerId = :UserInfo.getUserId()
        ]) {
            FilesOwnedByMe.add(
                new File(document)
            );
        }

        return FilesOwnedByMe;
    }

    @AuraEnabled
    public static List<File> getFilesSharedWithMe(){
        List<File> FilesOwnedByMe = new List<File>();
        for(ContentDocumentLink link : [
            SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileType, ContentDocument.ContentSize,
            ContentDocument.LastModifiedDate, ContentDocument.FileExtension
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :UserInfo.getUserId() AND ContentDocument.OwnerId != :UserInfo.getUserId()
        ]) {
            FilesOwnedByMe.add(
                new File(link)
            );
        }

        return FilesOwnedByMe;
    }

    @AuraEnabled
    public static List<File> getFollowingFiles(){
        Set<Id> followingFileIds = new Set<Id>();
        for(EntitySubscription entity : [
            SELECT ParentId
            FROM EntitySubscription
            WHERE SubscriberId = :UserInfo.getUserId()
        ]) {
            String subscriptionObjectType = entity.ParentId.getSObjectType().getDescribe().getName();
            if (subscriptionObjectType == 'ContentDocument') {
                followingFileIds.add(entity.ParentId);
            }
        }

        List<File> followingFiles = new List<File>();
        for(ContentDocument document : [
            SELECT Id, Title, ContentSize, FileType, FileExtension, LastModifiedDate
            FROM ContentDocument
            WHERE Id IN :followingFileIds
        ]) {
            followingFiles.add(
                new File(document)
            );
        }

        return followingFiles;
    }

    @AuraEnabled
    public static void createContentDocumentLinks(List<String> selectedFileIds, String recordId) {
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        for (String fileId : selectedFileIds) {
            linksToInsert.add(
                new ContentDocumentLink(
                    LinkedEntityId = recordId,
                    ContentDocumentId = fileId,
                    ShareType = 'V'
                )
            );
        }

        insert linksToInsert;
    }

    public class File {
        @AuraEnabled
        public Id Id { get; set; }
        @AuraEnabled
        public String Name { get; set; }
        @AuraEnabled
        public String Size { get; set; }
        @AuraEnabled
        public String Format { get; set; }
        @AuraEnabled
        public String Type { get; set; }
        @AuraEnabled
        public String LastModifiedDate { get; set; }

        public File (ContentDocument document) {
            this.Id = document.Id;
            this.Name = document.Title;
            this.Size = convertByteToSize(document.ContentSize);
            this.Format = document.FileExtension;
            this.Type = document.FileType;
            this.LastModifiedDate = document.LastModifiedDate.format();
        }

        public File (ContentDocumentLink link) {
            this.Id = link.ContentDocument.Id;
            this.Name = link.ContentDocument.Title;
            this.Size = convertByteToSize(link.ContentDocument.ContentSize);
            this.Format = link.ContentDocument.FileExtension;
            this.Type = link.ContentDocument.FileType;
            this.LastModifiedDate = link.ContentDocument.LastModifiedDate.format();
        }

        public File (ContentDocumentSubscription subscription) {
            this.Id = subscription.ContentDocument.Id;
            this.Name = subscription.ContentDocument.Title;
            this.Size = convertByteToSize(subscription.ContentDocument.ContentSize);
            this.Format = subscription.ContentDocument.FileExtension;
            this.Type = subscription.ContentDocument.FileType;
            this.LastModifiedDate = subscription.ContentDocument.LastModifiedDate.format();
        }

        private String convertByteToSize(Long bytes) {
            if (bytes == null || bytes == 0) {
                return '0 B';
            }
            Integer unit = 1024;
            String[] units = new String[]{'B', 'KB', 'MB', 'GB', 'TB', 'PB'};
            Decimal size = Math.log(bytes) / Math.log(unit);
            Integer index = Math.min((Integer)size.intValue(), units.size()-1);
            Decimal result = bytes / Math.pow(unit, index);
            return result.setScale(2) + units[index];
        }
    }
}