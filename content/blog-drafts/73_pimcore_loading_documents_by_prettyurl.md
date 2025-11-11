
        use Pimcore\Model\Element\Service;
        use Pimcore\Model\Document;

        try {
            $document = new Document();
            if (Service::isValidPath($documentPath, 'document')) {
                $document->getDao()->getByPath($documentPath);
                return $document;
            }
        } catch (\Exception $e) {
        }
