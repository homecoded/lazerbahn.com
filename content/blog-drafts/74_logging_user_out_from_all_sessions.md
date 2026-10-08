<?php
declare(strict_types=1);

namespace Triplewood\IDP\Model\Session;

use Cm\RedisSession\Handler;
use CredisException;

/**
 * This is a fairly low-level code that goes through the session data in redis and
 * deletes all data associated with a certain customer.
 * It identifies the corresponding data via regex and customer id.
 *
 * This class extends the RedisSession-Handler that Magento uses in
 * \Magento\Framework\Session\SaveHandler\Redis to communicate with Redis.
 */
class RedisHandler extends Handler
{
    private const string CUSTOMER_ID_REGEX = '/\"customer_id\";s:(\d*):\"%d\"/';

    public function deleteSessionDataByCustomerId(int $customerId) : array
    {
        if (!$this->_redis->isConnected()) {
            return [
                'success' => false,
                'message' => 'Could not connect to session storage.'
            ];
        }

        try {
            $this->_redis->select($this->_dbNum);
        } catch (CredisException $e) {
            return [
                'success' => false,
                'message' => $e->getMessage()
            ];
        }

        return $this->deleteSessionData($customerId);
    }

    private function deleteSessionData(int $customerId): array
    {
        $allKeys = $this->_redis->keys('sess_*');
        $deleteCount = 0;

        if (!is_array($allKeys) || count($allKeys) === 0) {
            return [
                'success' => false,
                'message' => 'No session data found in session storage.'
            ];
        }

        foreach ($allKeys as $key) {
            $data = $this->_redis->hMGet($key, ['data']);
            if (!is_array($data)) {
                continue;
            }
            $isCustomerSession = (bool)preg_match(
                sprintf(self::CUSTOMER_ID_REGEX, $customerId),
                (string) $data['data']
            );
            if ($isCustomerSession) {
                $deleteCount = $this->_redis->del($key);
                if (is_numeric($deleteCount)) {
                    $deleteCount += $deleteCount;
                }
            }

        }
        return [
            'success' => $deleteCount > 0,
            'message' => ($deleteCount > 0) ?
                'Session data deleted for customer' :
                'No session found for customer. Customer is not logged in.'
        ];
    }
}
